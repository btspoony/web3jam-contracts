/**

Web3Jam Participant contract
*/

import MetadataViews from "./standard/MetadataViews.cdc"
import Web3JamInterfaces from "./Web3JamInterfaces.cdc"

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
        pub fun participateCampaign(campaign: &{Web3JamInterfaces.CampaignPublic, MetadataViews.Resolver}) {
            let address = self.owner!.address
            assert(!campaign.hasJoined(account: address), message: "You have been joined to the campaign.")

            // join to campaign
            campaign.participate(account: address)

            let idType = Type<Web3JamInterfaces.CampaignIdentifier>()
            let identifier = campaign.resolveView(idType) ?? panic("Failed to resolve identifier view")
            self.joinedCompaigns.append(identifier as! Web3JamInterfaces.CampaignIdentifier)
        }

        // access voucher to join a project
        pub fun applyForProject(project: &{Web3JamInterfaces.ProjectPublic, MetadataViews.Resolver}) {
            // TODO

            // let address = self.owner!.address
            // assert(!project.hasJoined(account: address), message: "You have been joined to the project.")

            // // ensure campaign joined
            // let campaign = project.getCampaign()
            // if !campaign.hasJoined(account: address) {
            //     self.joinCampaign(campaign: campaign)
            // }

            // // join to project
            // project.join(account: address)

            // let idType = Type<Web3JamInterfaces.ProjectIdentifier>()
            // let identifier = project.resolveView(idType) ?? panic("Failed to resolve identifier view")
            // self.joinedProjects.append(identifier as! Web3JamInterfaces.ProjectIdentifier)
        }

        // --- Setters - Contract Only ---

        // --- Self Only ---
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