/**

Web3Jam Main contract
*/

import MetadataViews from "./standard/MetadataViews.cdc"
import Web3JamInterfaces from "./Web3JamInterfaces.cdc"
import StateMachine from "./StateMachine.cdc"
import Permissions from "./Permissions.cdc"

pub contract Web3Jam {

    /**    ___  ____ ___ _  _ ____
       *   |__] |__|  |  |__| [__
        *  |    |  |  |  |  | ___]
         *************************/

    pub let Web3JamHQStoragePath: StoragePath
    pub let Web3JamHQPublicPath: PublicPath
    pub let CompaignsControllerStoragePath: StoragePath
    pub let CompaignsControllerPrivatePath: PrivatePath
    pub let CompaignsControllerPublicPath: PublicPath

    /**    ____ _  _ ____ _  _ ___ ____
       *   |___ |  | |___ |\ |  |  [__
        *  |___  \/  |___ | \|  |  ___]
         ******************************/

    // emitted when contract initialized
    pub event ContractInitialized()

    // --- Project Events ---
    pub event ProjectCreated() // TODO

    // --- Campaign Events ---
    pub event CampaignCreated(id: UInt64, host: Address, name: String, description: String, image: String)
    pub event CampaignStatusUpdated() // TODO

    // --- Campaigns Controller Events ---
    pub event SponsorsAdded() // TODO
    pub event TagsAdded() // TODO

    pub event CampaignsControllerCreated(serial: UInt64)

    /**    ____ ___ ____ ___ ____
       *   [__   |  |__|  |  |___
        *  ___]  |  |  |  |  |___
         ************************/
    // total compaigns controller amount
    pub var totalControllers: UInt64
    // total compaign amount
    pub var totalCompaigns: UInt64
    // total project amount
    pub var totalProjects: UInt64

    /**    ____ _  _ _  _ ____ ___ _ ____ _  _ ____ _    _ ___ _   _
       *   |___ |  | |\ | |     |  | |  | |\ | |__| |    |  |   \_/
        *  |    |__| | \| |___  |  | |__| | \| |  | |___ |  |    |
         ***********************************************************/
    
    // Project
    pub resource Project: Web3JamInterfaces.ProjectMaintainer, Web3JamInterfaces.ProjectMember, Web3JamInterfaces.ProjectJudge, Web3JamInterfaces.ProjectPublic, Web3JamInterfaces.Web3JamPermissionTracker, MetadataViews.Resolver {
        // The `uuid` of this resource
        pub let id: UInt64
        // who hosted the campaign
        pub let host: Address
        // the campaign id
        pub let campaignId: UInt64
        // when created
        pub let dateCreated: UFix64
        // who created the project
        pub let creator: Capability<&{Web3JamInterfaces.AccessVoucherPublic}>
        // --- varibles can be modified by host ---
        pub var name: String
        pub var description: String
        pub var image: String?
        pub var tags: [Web3JamInterfaces.Tag]
        access(account) var members: {Address: Capability<&{Web3JamInterfaces.AccessVoucherPublic}>}
        access(account) var applicants: [Capability<&{Web3JamInterfaces.AccessVoucherPublic}>]
        access(account) var extensions: {String: AnyStruct}
        // --- varibles of project status ---
        // project delivery information
        access(account) var delivery: {String: AnyStruct}
        // fsm of the campaign
        access(self) let fsm: @StateMachine.FSM
        // permission keeper resource
        access(self) let permissionKeeper: @Permissions.PermissionsKeeper

        init(
            host: Address,
            campaignId: UInt64,
            creator: Capability<&{Web3JamInterfaces.AccessVoucherPublic}>,
            name: String,
            description: String,
            image: String?,
            tags: [Web3JamInterfaces.Tag],
            extensions: {String: AnyStruct}
        ) {
            self.id = self.uuid
            self.dateCreated = getCurrentBlock().timestamp
            self.host = host
            self.campaignId = campaignId
            self.creator = creator
            // variables
            self.name = name
            self.description = description
            self.image = image
            self.tags = tags
            self.extensions = extensions
            // dictionary or array
            self.members = {}
            self.applicants = []
            self.delivery = {}

            // build project FSM
            self.fsm <- StateMachine.createFSM(
                self.getType().identifier,
                states: {}, // TODO build FSM detail
                start: "recruiting"
            )

            // build permissions
            self.permissionKeeper <- Permissions.createPermissionsKeeper(
                resourceId: self.getType().identifier.concat(".").concat(self.uuid.toString()),
                permissionId: Web3JamInterfaces.PermissionKey.getType().identifier
            )
            // set permissions for admin addresses
            self.permissionKeeper.setPermission(Web3JamInterfaces.PermissionKey.projectMaintainer.rawValue, account: creator.address, whitelisted: true)
            self.permissionKeeper.setPermission(Web3JamInterfaces.PermissionKey.projectMember.rawValue, account: creator.address, whitelisted: true)

            Web3Jam.totalProjects = Web3Jam.totalProjects + 1

            emit ProjectCreated() // TODO fill Event data
        }

        destroy() {
            destroy self.permissionKeeper
            destroy self.fsm
        }

        // --- Getters - Public Interfaces ---

        // This is for the MetdataStandard
        pub fun getViews(): [Type] {
             return [
                Type<Web3JamInterfaces.ProjectIdentifier>()
            ]
        }

        // This is for the MetdataStandard
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<Web3JamInterfaces.ProjectIdentifier>():
                    return Web3JamInterfaces.ProjectIdentifier(
                        self.host,
                        self.campaignId,
                        self.id
                    ) 
            }
            return nil
        }

        pub fun hasPermission(_ key: Web3JamInterfaces.PermissionKey, account: Address): Bool {
            return self.permissionKeeper.hasPermission(key.rawValue, account: account)
        }

        pub fun getCurrentState(): String {
            return self.fsm.currentState
        }

        // has the account joined
        pub fun hasJoined(account: Address): Bool {
            return self.hasPermission(Web3JamInterfaces.PermissionKey.projectMember, account: account)
        }

        // get campaign inforamtion of the project
        pub fun getCampaign(): &{Web3JamInterfaces.CampaignPublic, MetadataViews.Resolver} {
            let controller = getAccount(self.host)
                .getCapability(Web3Jam.CompaignsControllerPublicPath)
                .borrow<&{Web3JamInterfaces.CampaignsControllerPublic}>()
                ?? panic("Failed to get campaign controler.")
            return controller.getCampaign(campaignID: self.campaignId)
                ?? panic("Failed to found campaignID: ".concat(self.campaignId.toString()))
        }

        // --- Setters - Private Interfaces ---

        // --- Setters - Contract Only ---

        // a new account to join the project
        // access(account) fun join(account: Address) {
        //     self.permissionKeeper.setPermission(Web3JamInterfaces.PermissionKey.projectMember.rawValue, account: account, whitelisted: true)
        // }

        // --- Self Only ---

    }

    // Campaign
    pub resource Campaign: Web3JamInterfaces.CampaignPublic, Web3JamInterfaces.CampaignMaintainer, Web3JamInterfaces.CampaignParticipant, Web3JamInterfaces.CampaignJudge, MetadataViews.Resolver, MetadataViews.ResolverCollection, Web3JamInterfaces.Web3JamPermissionTracker {
        // The `uuid` of this resource
        pub let id: UInt64
        // when created
        pub let dateCreated: UFix64
        // who created the campaign
        pub let creator: Capability<&{Web3JamInterfaces.AccessVoucherPublic}>
        // address of the campaigns controller
        pub let host: Address
        // --- varibles can be modified by host ---
        pub var name: String
        pub var description: String
        pub var image: String
        pub var duration: [UFix64; 2]
        pub var imageHeader: String?
        pub var guideUrl: String
        pub var registerUrl: String?
        access(account) var sponsors: [Web3JamInterfaces.Sponsor]
        access(account) var projectTags: [Web3JamInterfaces.Tag]
        access(account) var roleTags: [Web3JamInterfaces.Tag]
        access(account) var extensions: {String: AnyStruct}
        // --- varibles of campain status ---
        // all project resources
        access(account) var projects: @{UInt64: Project}
        // fsm of the campaign
        access(self) let fsm: @StateMachine.FSM
        // permission keeper resource
        access(self) let permissionKeeper: @Permissions.PermissionsKeeper

        init(
            creator: Capability<&{Web3JamInterfaces.AccessVoucherPublic}>,
            host: Address,
            name: String,
            description: String,
            image: String,
            imageHeader: String?,
            duration: [UFix64; 2],
            guideUrl: String,
            registerUrl: String?,
            sponsors: [Web3JamInterfaces.Sponsor],
            projectTags: [Web3JamInterfaces.Tag],
            roleTags: [Web3JamInterfaces.Tag],
            extensions: {String: AnyStruct}
        ) {
            self.id = self.uuid
            self.dateCreated = getCurrentBlock().timestamp
            self.creator = creator
            self.host = host
            // variables
            self.name = name
            self.description = description
            self.image = image
            self.imageHeader = imageHeader
            self.duration = duration
            self.guideUrl = guideUrl
            self.registerUrl = registerUrl
            // array or collection
            self.sponsors = sponsors
            self.projectTags = projectTags
            self.roleTags = roleTags
            self.extensions = extensions
            // resources
            self.projects <- {}

            // build permissions
            self.permissionKeeper <- Permissions.createPermissionsKeeper(
                resourceId: self.getType().identifier.concat(".").concat(self.uuid.toString()),
                permissionId: Web3JamInterfaces.PermissionKey.getType().identifier
            )
            // set permissions for admin addresses
            self.permissionKeeper.setPermission(Web3JamInterfaces.PermissionKey.campaignMaintainer.rawValue, account: host, whitelisted: true)
            if creator.address != host {
                self.permissionKeeper.setPermission(Web3JamInterfaces.PermissionKey.campaignMaintainer.rawValue, account: creator.address, whitelisted: true)
            }
            self.permissionKeeper.setPermission(Web3JamInterfaces.PermissionKey.campaignParticipant.rawValue, account: creator.address, whitelisted: true)

            // build campaign FSM
            self.fsm <- StateMachine.createFSM(
                self.getType().identifier,
                states: {}, // TODO build FSM detail
                start: "opening"
            )

            Web3Jam.totalCompaigns = Web3Jam.totalCompaigns + 1
            emit CampaignCreated(id: self.id, host: self.host, name: self.name, description: self.description, image: self.image)
        }

        destroy() {
            destroy self.fsm
            destroy self.projects
            destroy self.permissionKeeper
        }

        // --- Getters - Public Interfaces ---

        // This is for the MetdataStandard
        pub fun getViews(): [Type] {
             return [
                Type<Web3JamInterfaces.CampaignIdentifier>()
            ]
        }

        // This is for the MetdataStandard
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<Web3JamInterfaces.CampaignIdentifier>():
                    return Web3JamInterfaces.CampaignIdentifier(
                        self.host,
                        self.id
                    ) 
            }
            return nil
        }

        // This is for the Web3JamPermissionTracker
        pub fun hasPermission(_ key: Web3JamInterfaces.PermissionKey, account: Address): Bool {
            return self.permissionKeeper.hasPermission(key.rawValue, account: account)
        }

        // all ids of projects
        pub fun getIDs(): [UInt64] {
            return self.projects.keys
        }

        // This is for the MetdataStandard of projects
        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver} {
            return &self.projects[id] as! &{MetadataViews.Resolver}
        }

        // get project public interface
        pub fun getProject(projectID: UInt64): &{Web3JamInterfaces.ProjectPublic, MetadataViews.Resolver}? {
            return &self.projects[projectID] as? &{Web3JamInterfaces.ProjectPublic, MetadataViews.Resolver}
        }

        // get current fsm state 
        pub fun getCurrentState(): String {
            return self.fsm.currentState
        }

        // has the account joined
        pub fun hasJoined(account: Address): Bool {
            return self.hasPermission(Web3JamInterfaces.PermissionKey.campaignParticipant, account: account)
        }

        // get a sponsor
        pub fun getSponsor(idx: UInt64): Web3JamInterfaces.Sponsor {
            return self.sponsors[idx]
        }
        // get availble sponsor
        pub fun getAvailableSponsors(): [Web3JamInterfaces.Sponsor] {
            return self.sponsors
        }
        // get a tag
        pub fun getTag(type: Web3JamInterfaces.TagType, idx: UInt64): Web3JamInterfaces.Tag? {
            if type == Web3JamInterfaces.TagType.projectScope {
                return self.projectTags[idx]
            } else if type == Web3JamInterfaces.TagType.role {
                return self.roleTags[idx]
            }
            return nil
        }
        // get availble tags
        pub fun getAvailableTags(type: Web3JamInterfaces.TagType): [Web3JamInterfaces.Tag] {
            if type == Web3JamInterfaces.TagType.projectScope {
                return self.projectTags
            } else if type == Web3JamInterfaces.TagType.role {
                return self.roleTags
            }
            return []
        }

        // --- Setters - Private Interfaces ---
        // add sponsors
        pub fun addSponsors(sponsorsToAdd: [Web3JamInterfaces.Sponsor]) {
            self.sponsors.appendAll(sponsorsToAdd)
        }

        // add tags
        pub fun addTags(type: Web3JamInterfaces.TagType, tagsToAdd: [Web3JamInterfaces.Tag]) {
            if type == Web3JamInterfaces.TagType.projectScope {
                self.projectTags.appendAll(tagsToAdd)
            } else if type == Web3JamInterfaces.TagType.role {
                self.roleTags.appendAll(tagsToAdd)
            }
        }

        // --- Setters - Contract Only ---

        // a new account to join the campaign
        access(account) fun join(account: Address) {
            self.permissionKeeper.setPermission(Web3JamInterfaces.PermissionKey.campaignParticipant.rawValue, account: account, whitelisted: true)
        }

        // --- Self Only ---

    }

    // Campaigns controller
    pub resource CampaignsController: Web3JamInterfaces.CampaignsControllerPublic, Web3JamInterfaces.CampaignsControllerPrivate, Web3JamInterfaces.Web3JamPermissionTracker {
        access(self) let serial: UInt64
        // permission keeper resource
        access(self) let permissionKeeper: @Permissions.PermissionsKeeper
        // get access to hq public
        pub let hq: Capability<&Web3Jam.Web3JamHQ{Web3JamInterfaces.Web3JamHQPublic}>
        // all campaigns you created
        access(account) var campaigns: @{UInt64: Campaign}

        init(
            _ hq: Capability<&Web3Jam.Web3JamHQ{Web3JamInterfaces.Web3JamHQPublic}>
        ) {
            self.hq = hq
            self.campaigns <- {}
            self.serial = Web3Jam.totalCompaigns

            self.permissionKeeper <- Permissions.createPermissionsKeeper(
                resourceId: self.getType().identifier.concat(".").concat(self.uuid.toString()),
                permissionId: Web3JamInterfaces.PermissionKey.getType().identifier
            )

            Web3Jam.totalCompaigns = Web3Jam.totalCompaigns + 1
            emit CampaignsControllerCreated(serial: self.serial)
        }

        destroy () {
            destroy self.campaigns
            destroy self.permissionKeeper
        }

        // --- Getters - Public Interfaces ---

        // all ids of compaigns
        pub fun getIDs(): [UInt64] {
            return self.campaigns.keys
        }

        // get campaign public
        pub fun getCampaign(campaignID: UInt64): &{Web3JamInterfaces.CampaignPublic, MetadataViews.Resolver}? {
            return &self.campaigns[campaignID] as? &{Web3JamInterfaces.CampaignPublic, MetadataViews.Resolver}
        }
        
        pub fun hasPermission(_ key: Web3JamInterfaces.PermissionKey, account: Address): Bool {
            if account == self.owner!.address {
                return true
            }
            return self.permissionKeeper.hasPermission(key.rawValue, account: account)
        }

        pub fun isMaintainer(_ account: Address): Bool {
            return self.hasPermission(Web3JamInterfaces.PermissionKey.campaignsControllerMaintainer, account: account)
        }

        // --- Setters - Private Interfaces ---

        // create a new compain resource
        pub fun createCompaign(
            creator: Capability<&{Web3JamInterfaces.AccessVoucherPublic}>,
            name: String,
            description: String,
            image: String,
            imageHeader: String?,
            guideUrl: String,
            registerUrl: String?,
            startTime: UFix64?,
            endTime: UFix64,
            sponsors: [Web3JamInterfaces.Sponsor],
            projectTags: [Web3JamInterfaces.Tag],
            roleTags: [Web3JamInterfaces.Tag],
            _ extensions: {String: AnyStruct}
        ): UInt64 {
            pre {
                self.isControllable(): "Current controller is invalid."
                self.isMaintainer(creator.address): "Current creator is not a maintainer."
            }

            let campaign <- create Campaign(
                creator: creator,
                host: self.owner!.address,
                name: name,
                description: description,
                image: image,
                imageHeader: imageHeader,
                duration: [ startTime ?? getCurrentBlock().timestamp, endTime],
                guideUrl: guideUrl,
                registerUrl: registerUrl,
                sponsors: sponsors,
                projectTags: projectTags,
                roleTags: roleTags,
                extensions: extensions
            )

            let campainId = campaign.id
            self.campaigns[campainId] <-! campaign

            return campainId
        }

        pub fun setMaintainer(account: Address, whitelisted: Bool) {
            pre {
                self.isControllable(): "Current controller is invalid"
            }
            self.permissionKeeper.setPermission(Web3JamInterfaces.PermissionKey.campaignsControllerMaintainer.rawValue, account: account, whitelisted: whitelisted)
        }

        // only administrator can set whitelist
        pub fun setHQWhitelisted(_ key: Web3JamInterfaces.PermissionKey, account: Address, whitelisted: Bool) {
            pre {
                self.isAdministrator(): "Current controller should be an administrator of HQ"
            }

            let privRef = self.hq.borrow()!.borrowHQPrivateRef()
            privRef.setWhitelisted(key, account: account, whitelisted: whitelisted)
        }

        // --- Self Only ---

        // internal methods
        access(self) fun isControllable(): Bool {
            return self.hq.borrow()!.isWhitelisted(Web3JamInterfaces.PermissionKey.campaignsControllerWhitelist, account: self.owner!.address)
        }
        access(self) fun isAdministrator(): Bool {
            return self.hq.borrow()!.isWhitelisted(Web3JamInterfaces.PermissionKey.administrator, account: self.owner!.address)
        }
    }

    // Web3 Jam HQ information
    pub resource Web3JamHQ: Web3JamInterfaces.Web3JamHQPublic, Web3JamInterfaces.Web3JamHQPrivate, Web3JamInterfaces.Web3JamPermissionTracker {
        // permission keeper resource
        access(self) let permissionKeeper: @Permissions.PermissionsKeeper
        // current opening campaign ids
        access(self) var openingCampaigns: [Web3JamInterfaces.CampaignIdentifier]

        init(_ admin: Address) {
            self.openingCampaigns = []

            self.permissionKeeper <- Permissions.createPermissionsKeeper(
                resourceId: self.getType().identifier.concat(".").concat(self.uuid.toString()),
                permissionId: Web3JamInterfaces.PermissionKey.getType().identifier
            )
            // set permissions for admin address
            self.permissionKeeper.setPermission(Web3JamInterfaces.PermissionKey.administrator.rawValue, account: admin, whitelisted: true)
            self.permissionKeeper.setPermission(Web3JamInterfaces.PermissionKey.campaignsControllerWhitelist.rawValue, account: admin, whitelisted: true)
        }

        destroy() {
            destroy self.permissionKeeper
        }

        // --- Getters - Public Interfaces ---

        // get current opening campaign ids
        pub fun getOpeningCampaignIDs(): [Web3JamInterfaces.CampaignIdentifier] {
            // TODO update openingCampaigns
            return self.openingCampaigns
        }

        // is some address whitedlisted for some white list key
        pub fun isWhitelisted(_ key: Web3JamInterfaces.PermissionKey, account: Address): Bool {
            return self.hasPermission(key, account: account)
        }
        pub fun hasPermission(_ key: Web3JamInterfaces.PermissionKey, account: Address): Bool {
            return self.permissionKeeper.hasPermission(key.rawValue, account: account)
        }

        // --- Setters - Private Interfaces ---

        // --- Setters - Contract Only ---

        // only access by this contract
        access(account) fun setWhitelisted(_ key: Web3JamInterfaces.PermissionKey, account: Address, whitelisted: Bool) {
            self.permissionKeeper.setPermission(key.rawValue, account: account, whitelisted: whitelisted)
        }

        // only used for account contract internal
        access(account) fun borrowHQPrivateRef(): &AnyResource{Web3JamInterfaces.Web3JamHQPrivate} {
            return &self as &{Web3JamInterfaces.Web3JamHQPrivate}
        }
    }

    // create a new campaign controller resource
    pub fun createCampaignController(hq: Capability<&Web3Jam.Web3JamHQ{Web3JamInterfaces.Web3JamHQPublic}>): @CampaignsController {
        return <- create CampaignsController(hq)
    }

    init() {
        self.totalControllers = 0
        self.totalCompaigns = 0
        self.totalProjects = 0
        
        // Set the named paths
        self.Web3JamHQStoragePath  = /storage/Web3JamHQPath
        self.Web3JamHQPublicPath = /public/Web3JamHQPath
        self.CompaignsControllerStoragePath = /storage/Web3JamCompaignsControllerPath
        self.CompaignsControllerPublicPath = /public/Web3JamCompaignsControllerPath
        self.CompaignsControllerPrivatePath = /private/Web3JamCompaignsControllerPath

        // Create HQ resource
        self.account.save(
            <- create Web3JamHQ(self.account.address),
            to: self.Web3JamHQStoragePath
        )
        let cap = self.account.link<&Web3Jam.Web3JamHQ{Web3JamInterfaces.Web3JamHQPublic}>(
            self.Web3JamHQPublicPath,
            target: self.Web3JamHQStoragePath
        )

        // Create a compaigns controller
        self.account.save(
            <- Web3Jam.createCampaignController(hq: cap!),
            to: self.CompaignsControllerStoragePath
        )
        self.account.link<&Web3Jam.CampaignsController{Web3JamInterfaces.CampaignsControllerPublic}>(
            self.CompaignsControllerPublicPath,
            target: self.CompaignsControllerStoragePath
        )
        self.account.link<&Web3Jam.CampaignsController{Web3JamInterfaces.CampaignsControllerPrivate}>(
            self.CompaignsControllerPrivatePath,
            target: self.CompaignsControllerStoragePath
        )

        emit ContractInitialized()
    }
}
