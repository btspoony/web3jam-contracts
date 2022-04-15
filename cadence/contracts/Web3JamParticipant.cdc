/**

Web3Jam Participant contract
*/

import MetadataViews from "./standard/MetadataViews.cdc"
import Web3JamInterfaces from "./Web3JamInterfaces.cdc"
import Web3Jam from "./Web3Jam.cdc"

pub contract Web3JamParticipant {

    /**    ___  ____ ___ _  _ ____
       *   |__] |__|  |  |__| [__
        *  |    |  |  |  |  | ___]
         *************************/
    
    pub let AccessVoucherStoragePath: StoragePath
    pub let AccessVoucherPrivatePath: PrivatePath
    pub let AccessVoucherPublicPath: PublicPath

    /**    ____ _  _ ____ _  _ ___ ____
       *   |___ |  | |___ |\ |  |  [__
        *  |___  \/  |___ | \|  |  ___]
         ******************************/

    // emitted when contract initialized
    pub event ContractInitialized()

    // --- Access Voucher ---
    pub event AccessVoucherCreated(serial: UInt64)

    /**    ____ ___ ____ ___ ____
       *   [__   |  |__|  |  |___
        *  ___]  |  |  |  |  |___
         ************************/
    
    // total access voucher amount
    pub var totalAccessVouchers: UInt64

    /**    ____ _  _ _  _ ____ ___ _ ____ _  _ ____ _    _ ___ _   _
       *   |___ |  | |\ | |     |  | |  | |\ | |__| |    |  |   \_/
        *  |    |__| | \| |___  |  | |__| | \| |  | |___ |  |    |
         ***********************************************************/
    
    // Web3Jam access token
    pub resource AccessVoucher: Web3JamInterfaces.AccessVoucherPublic, Web3JamInterfaces.AccessVoucherPrivate {
        // Access Voucher serial number
        pub let serial: UInt64

        // voucher metadata
        access(account) var metadata: {String: AnyStruct}

        // access records
        access(account) var joinedProjects: [Web3JamInterfaces.ProjectIdentifier]
        access(account) var joinedCompaigns: [Web3JamInterfaces.CampaignIdentifier]

        init() {
            self.serial = Web3JamParticipant.totalAccessVouchers

            self.joinedCompaigns = []
            self.joinedProjects = []
            self.metadata = {}

            Web3JamParticipant.totalAccessVouchers = Web3JamParticipant.totalAccessVouchers + 1
            emit AccessVoucherCreated(serial: self.serial)
        }

        // --- Getters - Public Interfaces ---

        pub fun getAddress(): Address {
            return self.owner!.address
        }

        pub fun getMetadata(): {String: AnyStruct} {
            return self.metadata
        }

        pub fun getCampaignPermissions(campaign: Web3JamInterfaces.CampaignIdentifier): [Web3JamInterfaces.PermissionKey] {
            let campaignRef = self.getCampaign(campaign: campaign) ?? panic("Failed to get campaign: ".concat(campaign.campaignId.toString()))
            let permissions = campaignRef.getPermissionsTracker().getPermissions(account: self.owner!.address)

            let ret:[Web3JamInterfaces.PermissionKey] = []
            for one in permissions {
                ret.append(Web3JamInterfaces.PermissionKey(rawValue: one)!)
            }
            return ret
        }

        pub fun getProjectPermissions(project: Web3JamInterfaces.ProjectIdentifier): [Web3JamInterfaces.PermissionKey] {
            let projectRef = self.getProject(project: project) ?? panic("Failed to get project: ".concat(project.projectId.toString()))
            let permissions = projectRef.getPermissionsTracker().getPermissions(account: self.owner!.address)
            
            let ret:[Web3JamInterfaces.PermissionKey] = []
            for one in permissions {
                ret.append(Web3JamInterfaces.PermissionKey(rawValue: one)!)
            }
            return ret
        }

        // --- Setters - Private Interfaces ---

        // Update the metadata
        pub fun setMetadata(key: String, value: AnyStruct) {
            self.metadata[key] = value
        }
        // Batch update the metadata
        pub fun updateMetadata(data: {String: AnyStruct}) {
            for key in data.keys {
                self.metadata[key] = data[key]
            }
        }

        // access voucher to join a campaign
        pub fun participateCampaign(campaign: Web3JamInterfaces.CampaignIdentifier) {
            let address = self.owner!.address

            let campaignRef = self.getCampaign(campaign: campaign) ?? panic("Failed to get campaign: ".concat(campaign.campaignId.toString()))
            let tracker = campaignRef.getPermissionsTracker()
            assert(
                !tracker.hasPermission(Web3JamInterfaces.PermissionKey.campaignParticipant.rawValue, account: address),
                message: "You have been joined to the campaign."
            )

            // participate in to campaign
            campaignRef.participate(account: address)
            // append to compaign
            self.joinedCompaigns.append(campaign)
        }

        // access voucher to join a project
        pub fun applyForProject(project: Web3JamInterfaces.ProjectIdentifier) {
            let address = self.owner!.address

            let projectRef = self.getProject(project: project) ?? panic("Failed to get project: ".concat(project.projectId.toString()))
            let tracker = projectRef.getPermissionsTracker()
            assert(
                !tracker.hasPermission(Web3JamInterfaces.PermissionKey.projectMember.rawValue, account: address),
                message: "You have bean joined to the project."
            )

            // ensure campaign joined
            let campaignRef = projectRef.getCampaign()
            let campaignPermissionsTracker = campaignRef.getPermissionsTracker()
            if !tracker.hasPermission(Web3JamInterfaces.PermissionKey.campaignParticipant.rawValue, account: address) {
                self.participateCampaign(campaign: project.campaign)
            }

            // apply for the project
            projectRef.applyFor(account: address)
        }

        // campaign related
        pub fun checkAndBorrowCampaignMaintainerRef(campaign: Web3JamInterfaces.CampaignIdentifier): &{Web3JamInterfaces.CampaignMaintainer} {
            let campaignRef = self.getCampaign(campaign: campaign) ?? panic("Failed to get campaign: ".concat(campaign.campaignId.toString()))
            return campaignRef.checkAndBorrowMaintainerRef(account: self.owner!.address)
        }

        pub fun checkAndBorrowCampaignParticipantRef(campaign: Web3JamInterfaces.CampaignIdentifier): &{Web3JamInterfaces.CampaignParticipant} {
            let campaignRef = self.getCampaign(campaign: campaign) ?? panic("Failed to get campaign: ".concat(campaign.campaignId.toString()))
            return campaignRef.checkAndBorrowParticipantRef(account: self.owner!.address)
        }

        pub fun checkAndBorrowCampaignJudgeRef(campaign: Web3JamInterfaces.CampaignIdentifier): &{Web3JamInterfaces.CampaignJudge} {
            let campaignRef = self.getCampaign(campaign: campaign) ?? panic("Failed to get campaign: ".concat(campaign.campaignId.toString()))
            return campaignRef.checkAndBorrowJudgeRef(account: self.owner!.address)
        }

        // project related
        pub fun checkAndBorrowProjectMaintainerRef(project: Web3JamInterfaces.ProjectIdentifier): &{Web3JamInterfaces.ProjectMaintainer} {
            let projectRef = self.getProject(project: project) ?? panic("Failed to get project: ".concat(project.projectId.toString()))
            return projectRef.checkAndBorrowMaintainerRef(account: self.owner!.address)
        }

        pub fun checkAndBorrowProjectMemberRef(project: Web3JamInterfaces.ProjectIdentifier): &{Web3JamInterfaces.ProjectMember} {
            let projectRef = self.getProject(project: project) ?? panic("Failed to get project: ".concat(project.projectId.toString()))
            return projectRef.checkAndBorrowMemberRef(account: self.owner!.address)
        }

        pub fun checkAndBorrowProjectJudgeRef(project: Web3JamInterfaces.ProjectIdentifier): &{Web3JamInterfaces.ProjectJudge} {
            let projectRef = self.getProject(project: project) ?? panic("Failed to get project: ".concat(project.projectId.toString()))
            return projectRef.checkAndBorrowJudgeRef(account: self.owner!.address)
        }

        // --- Setters - Contract Only ---

        access(account) fun addToProject(project: Web3JamInterfaces.ProjectIdentifier) {
            // append to project
            self.joinedProjects.append(project)
        }

        // --- Self Only ---

        access(self) fun getCampaign(campaign: Web3JamInterfaces.CampaignIdentifier): &{Web3JamInterfaces.CampaignPublic, MetadataViews.Resolver}? {
            let controller = getAccount(campaign.controller)
                .getCapability(Web3Jam.CompaignsControllerPublicPath)
                .borrow<&{Web3JamInterfaces.CampaignsControllerPublic}>()
                ?? panic("Failed to get campaign controller.")
            return controller.getCampaign(campaignID: campaign.campaignId)
        }

        access(self) fun getProject(project: Web3JamInterfaces.ProjectIdentifier): &{Web3JamInterfaces.ProjectPublic, MetadataViews.Resolver}? {
            let controller = getAccount(project.campaign.controller)
                .getCapability(Web3Jam.CompaignsControllerPublicPath)
                .borrow<&{Web3JamInterfaces.CampaignsControllerPublic}>()
                ?? panic("Failed to get campaign controller.")
            let campaign = controller.getCampaign(campaignID: project.campaign.campaignId)
                ?? panic("Failed to get campaign: ".concat(project.campaign.campaignId.toString()))
            return campaign.getProject(projectID: project.projectId)
        }
    }
    
    // create an access voucher resource
    pub fun createAccessVoucher(): @AccessVoucher {
        return <- create AccessVoucher()
    }

    init() {
        self.totalAccessVouchers = 0

        self.AccessVoucherStoragePath = /storage/Web3JamAccessVoucherPath
        self.AccessVoucherPublicPath = /public/Web3JamAccessVoucherPath
        self.AccessVoucherPrivatePath = /private/Web3JamAccessVoucherPath
    }
}