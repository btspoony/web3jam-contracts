/**

Web3Jam Main contract
*/

import MetadataViews from "./standard/MetadataViews.cdc"
import Web3JamInterfaces from "./Web3JamInterfaces.cdc"
import StateMachine from "./StateMachine.cdc"

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
    pub let AccessVoucherStoragePath: StoragePath
    pub let AccessVoucherPublicPath: PublicPath

    /**    ____ _  _ ____ _  _ ___ ____
       *   |___ |  | |___ |\ |  |  [__
        *  |___  \/  |___ | \|  |  ___]
         ******************************/

    // emitted when contract initialized
    pub event ContractInitialized()

    // --- Access Voucher ---
    pub event AccessVoucherCreated(serial: UInt64)

    // --- Project Events ---
    pub event ProjectCreated() // TODO

    // --- Campaign Events ---
    pub event CampaignCreated(id: UInt64, host: Address, name: String, description: String, image: String)
    pub event CampaignStatusUpdated() // TODO

    // --- Campaigns Controller Events ---
    pub event SponsorsAdded() // TODO
    pub event TagsAdded() // TODO

    // --- Web3Jam HQ Events ---
    pub event WhitelistUpdated(key: UInt8, account: Address, whitelisted: Bool)

    /**    ____ ___ ____ ___ ____
       *   [__   |  |__|  |  |___
        *  ___]  |  |  |  |  |___
         ************************/
    
    // total compaign amount
    pub var totalCompaigns: UInt64
    // total project amount
    pub var totalProjects: UInt64
    // total access voucher amount
    pub var totalAccessVouchers: UInt64

    /**    ____ _  _ _  _ ____ ___ _ ____ _  _ ____ _    _ ___ _   _
       *   |___ |  | |\ | |     |  | |  | |\ | |__| |    |  |   \_/
        *  |    |__| | \| |___  |  | |__| | \| |  | |___ |  |    |
         ***********************************************************/
    
    // Web3Jam access token
    pub resource AccessVoucher: Web3JamInterfaces.AccessVoucherPublic {
        // Access Voucher serial number
        pub let serial: UInt64
        // voucher metadata
        access(account) var metadata: {String: AnyStruct}

        // access records
        access(account) var joinedProjects: [Web3JamInterfaces.ProjectIdentifier]
        access(account) var joinedCompaigns: [Web3JamInterfaces.CampaignIdentifier]

        init() {
            self.serial = Web3Jam.totalAccessVouchers

            self.joinedCompaigns = []
            self.joinedProjects = []
            self.metadata = {}

            Web3Jam.totalAccessVouchers = Web3Jam.totalAccessVouchers + 1
            emit AccessVoucherCreated(serial: self.serial)
        }

        // --- Getters - Public Interfaces ---

        // --- Setters - Private Interfaces ---

        // --- Setters - Contract Only ---

        // --- Self Only ---
    }
    
    // Project
    pub resource Project {
        // The `uuid` of this resource
        pub let id: UInt64

        init(
        ) {
            self.id = self.uuid

            Web3Jam.totalProjects = Web3Jam.totalProjects + 1
            emit ProjectCreated()
        }

        // --- Getters - Public Interfaces ---

        // --- Setters - Private Interfaces ---

        // --- Setters - Contract Only ---

        // --- Self Only ---

    }

    // Campaign
    pub resource Campaign: Web3JamInterfaces.CampaignPublic, Web3JamInterfaces.CampaignPrivate {
        // The `uuid` of this resource
        pub let id: UInt64
        // when created
        pub let dateCreated: UFix64
        // who created the campaign
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
        // fsm of the campaign
        access(account) let fsm: @StateMachine.FSM
        pub var projects: @{String: Project}

        init(
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
        }

        // --- Getters - Public Interfaces ---
        // get current fsm state 
        pub fun getCurrentState(): String {
            return self.fsm.currentState
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

        // --- Self Only ---

    }

    // Campaigns controller
    pub resource CampaignsController: Web3JamInterfaces.CampaignsControllerPublic, Web3JamInterfaces.CampaignsControllerPrivate {
        // get access to hq public
        pub let hq: Capability<&Web3Jam.Web3JamHQ{Web3JamInterfaces.Web3JamHQPublic}>
        // all campaigns you created
        access(account) var campaigns: @{UInt64: Campaign}

        init(
            _ hq: Capability<&Web3Jam.Web3JamHQ{Web3JamInterfaces.Web3JamHQPublic}>
        ) {
            self.hq = hq
            self.campaigns <- {}
        }

        destroy () {
            destroy self.campaigns
        }

        // --- Getters - Public Interfaces ---

        // all ids of compaigns
        pub fun getIDs(): [UInt64] {
            return self.campaigns.keys
        }

        // --- Setters - Private Interfaces ---

        // create a new compain resource
        pub fun createCompaign(
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
                self.isControllable(): "Current controller is invalid"
            }

            let campaign <- create Campaign(
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

        // only administrator can set whitelist
        pub fun setHQWhitelisted(_ key: Web3JamInterfaces.WhiteListKey, account: Address, whitelisted: Bool) {
            pre {
                self.isAdministrator(): "Current controller should be an administrator of HQ"
            }

            let privRef = self.hq.borrow()!.borrowHQPrivateRef()
            privRef.setWhitelisted(key, account: account, whitelisted: whitelisted)
        }

        // --- Self Only ---

        // internal methods
        access(self) fun isControllable(): Bool {
            return self.hq.borrow()!.isWhitelisted(Web3JamInterfaces.WhiteListKey.fullControl, account: self.owner!.address)
        }
        access(self) fun isAdministrator(): Bool {
            return self.hq.borrow()!.isWhitelisted(Web3JamInterfaces.WhiteListKey.administrator, account: self.owner!.address)
        }
    }

    // Web3 Jam HQ information
    pub resource Web3JamHQ: Web3JamInterfaces.Web3JamHQPublic, Web3JamInterfaces.Web3JamHQPrivate {
        // whitelisted controller accounts
        access(account) var whitelistedAccounts: {Web3JamInterfaces.WhiteListKey: [Address]}
        // current opening campaign ids
        access(self) var openingCampaigns: [Web3JamInterfaces.CampaignIdentifier]

        init(_ admin: Address) {
            self.whitelistedAccounts = {
                Web3JamInterfaces.WhiteListKey.administrator: [ admin ],
                Web3JamInterfaces.WhiteListKey.fullControl: [ admin ]
            }
            self.openingCampaigns = []
        }

        // --- Getters - Public Interfaces ---

        // get current opening campaign ids
        pub fun getOpeningCampaignIDs(): [Web3JamInterfaces.CampaignIdentifier] {
            // TODO update openingCampaigns
            return self.openingCampaigns
        }

        // is some address whitedlisted for some white list key
        pub fun isWhitelisted(_ key: Web3JamInterfaces.WhiteListKey, account: Address): Bool {
            if let list = self.whitelistedAccounts[key] {
                return list.contains(account)
            }
            return false
        }

        // --- Setters - Private Interfaces ---

        // --- Setters - Contract Only ---

        // only access by this contract
        access(account) fun setWhitelisted(_ key: Web3JamInterfaces.WhiteListKey, account: Address, whitelisted: Bool) {
            if let list = self.whitelistedAccounts[key] {
                if whitelisted && !list.contains(account) {
                    list.append(account)
                    emit WhitelistUpdated(key: key.rawValue, account: account, whitelisted: whitelisted)
                } else if !whitelisted && list.contains(account) {
                    for idx, addr in list {
                        if addr == account {
                            list.remove(at: idx)
                            break
                        }
                    }
                }
            } else if whitelisted {
                self.whitelistedAccounts[key] = [ account ]
            }
        }

        // only used for account contract internal
        access(account) fun borrowHQPrivateRef(): &AnyResource{Web3JamInterfaces.Web3JamHQPrivate} {
            return &self as &{Web3JamInterfaces.Web3JamHQPrivate}
        }
    }

    // create an access voucher resource
    pub fun createAccessVoucher(): @AccessVoucher {
        return <- create AccessVoucher()
    }

    // create a new campaign controller resource
    pub fun createCampaignController(hq: Capability<&Web3Jam.Web3JamHQ{Web3JamInterfaces.Web3JamHQPublic}>): @CampaignsController {
        return <- create CampaignsController(hq)
    }

    init() {
        self.totalCompaigns = 0
        self.totalProjects = 0
        self.totalAccessVouchers = 0
        
        // Set the named paths
        self.Web3JamHQStoragePath  = /storage/Web3JamHQPath
        self.Web3JamHQPublicPath = /public/Web3JamHQPath
        self.CompaignsControllerStoragePath = /storage/Web3JamCompaignsControllerPath
        self.CompaignsControllerPublicPath = /public/Web3JamCompaignsControllerPath
        self.CompaignsControllerPrivatePath = /private/Web3JamCompaignsControllerPath
        self.AccessVoucherStoragePath = /storage/Web3JamAccessVoucherPath
        self.AccessVoucherPublicPath = /public/Web3JamAccessVoucherPath

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
