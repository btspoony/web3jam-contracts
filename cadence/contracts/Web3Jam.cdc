/**

Web3Jam Main contract
*/

import MetadataViews from "./standard/MetadataViews.cdc"
import Web3JamInterfaces from "./Web3JamInterfaces.cdc"

pub contract Web3Jam {

    /**    ___  ____ ___ _  _ ____
       *   |__] |__|  |  |__| [__
        *  |    |  |  |  |  | ___]
         *************************/

    pub let Web3JamHQStoragePath: StoragePath
    pub let Web3JamHQPublicPath: PublicPath

    /**    ____ _  _ ____ _  _ ___ ____
       *   |___ |  | |___ |\ |  |  [__
        *  |___  \/  |___ | \|  |  ___]
         ******************************/

    // emitted when contract initialized
    pub event ContractInitialized()

    pub event WhitelistUpdated(key: UInt8, account: Address, whitelisted: Bool)

    /**    ____ ___ ____ ___ ____
       *   [__   |  |__|  |  |___
        *  ___]  |  |  |  |  |___
         ************************/
    
    // total compaign amount
    pub var totalCompaigns: UInt64

    /**    ____ _  _ _  _ ____ ___ _ ____ _  _ ____ _    _ ___ _   _
       *   |___ |  | |\ | |     |  | |  | |\ | |__| |    |  |   \_/
        *  |    |__| | \| |___  |  | |__| | \| |  | |___ |  |    |
         ***********************************************************/
    
    // Campaign
    pub resource Campaign {
        pub let id: UInt64

        init(
            id: UInt64
        ) {
            self.id = id
        }
    }

    // Campaigns controller
    pub resource CampaignsController: Web3JamInterfaces.CampaignsControllerPublic {
        // get access to hq public
        pub let hq: Capability<&Web3Jam.Web3JamHQ{Web3JamInterfaces.Web3JamHQPublic}>
        // all campaigns you created
        access(account) var campaigns: @{UInt64: Campaign}
        access(account) var sponsors: [Web3JamInterfaces.Sponsor]
        access(account) var tags: [Web3JamInterfaces.Tag]

        init(
            _ hq: Capability<&Web3Jam.Web3JamHQ{Web3JamInterfaces.Web3JamHQPublic}>
        ) {
            self.hq = hq
            self.campaigns <- {}
            self.sponsors = []
            self.tags = []
        }

        destroy () {
            destroy self.campaigns
        }

        // --- Getters - Public Interfaces ---

        // all ids of compaigns
        pub fun getIDs(): [UInt64] {
            return self.campaigns.keys
        }
        pub fun getSponsor(idx: UInt64): Web3JamInterfaces.Sponsor {
            return self.sponsors[idx]
        }
        pub fun getAvailableSponsors(): [Web3JamInterfaces.Sponsor] {
            return  self.sponsors
        }
        pub fun getTag(idx: UInt64): Web3JamInterfaces.Tag {
            return self.tags[idx]
        }
        pub fun getAvailableTags(type: Web3JamInterfaces.TagType): [Web3JamInterfaces.Tag] {
            var resultTags: [Web3JamInterfaces.Tag] = []
            for tag in self.tags {
                if tag.type == type {
                    resultTags.append(tag)
                }
            }
            return resultTags
        }

        // --- Setters - Private Interfaces ---
        // add sponsors
        pub fun addSponsors(sponsorsToAdd: [Web3JamInterfaces.Sponsor]) {
            pre {
                self.isControllable(): "Current controller is invalid"
            }
            self.sponsors.appendAll(sponsorsToAdd)
        }

        // add tags
        pub fun addTags(tagsToAdd: [Web3JamInterfaces.Tag]) {
            pre {
                self.isControllable(): "Current controller is invalid"
            }
            self.tags.appendAll(tagsToAdd)
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
        access(self) var openingCampaigns: [Web3JamInterfaces.CampaignIdentitier]

        init(_ admin: Address) {
            self.whitelistedAccounts = {
                Web3JamInterfaces.WhiteListKey.administrator: [ admin ],
                Web3JamInterfaces.WhiteListKey.fullControl: [ admin ]
            }
            self.openingCampaigns = []
        }

        // get current opening campaign ids
        pub fun getOpeningCampaignIDs(): [Web3JamInterfaces.CampaignIdentitier] {
            return self.openingCampaigns
        }

        // is some address whitedlisted for some white list key
        pub fun isWhitelisted(_ key: Web3JamInterfaces.WhiteListKey, account: Address): Bool {
            if let list = self.whitelistedAccounts[key] {
                return list.contains(account)
            }
            return false
        }

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

    // create a new campaign controller resource
    pub fun createCampaignController(hq: Capability<&Web3Jam.Web3JamHQ{Web3JamInterfaces.Web3JamHQPublic}>): @CampaignsController {
        return <- create CampaignsController(hq)
    }

    init() {
        self.totalCompaigns = 0
        
        // Set the named paths
        self.Web3JamHQStoragePath  = /storage/Web3JamWeb3JamHQ
        self.Web3JamHQPublicPath = /public/Web3JamWeb3JamHQ

        self.account.save(
        // Create an manager resource and save it to storage
            <- create Web3JamHQ(self.account.address),
            to: self.Web3JamHQStoragePath
        )
        // create a public capability for the manager resource
        self.account.link<&Web3Jam.Web3JamHQ{Web3JamInterfaces.Web3JamHQPublic}>(
            self.Web3JamHQPublicPath,
            target: self.Web3JamHQStoragePath
        )

        emit ContractInitialized()
    }
}