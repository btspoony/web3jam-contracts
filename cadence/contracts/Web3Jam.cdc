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

    // Sponsor
    pub resource Sponsor: MetadataViews.Resolver {
        // sponsor information
        pub let name: String
        pub var description: String
        pub var thumbnail: String

        // sponsor admin groups
        pub var controllers: [Address]

        init(
            name: String,
            description: String,
            thumbnail: String,
            admin: Address
        ) {
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.controllers = [ admin ]
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
            }
            return nil
        }
    }
    
    // Campaign
    pub resource Campaign {
        pub let id: UInt64

        init(
            id: UInt64
        ) {
            self.id = id
        }
    }

    pub resource CampaignsController {
        // get access to hq public
        pub let hq: Capability<&Web3Jam.Web3JamHQ{Web3JamInterfaces.Web3JamHQPublic}>
        // all campaign dictionary
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

        pub fun getIDs(): [UInt64] {
            return self.campaigns.keys
        }

    }

    // Campaigns manager
    pub resource Web3JamHQ: Web3JamInterfaces.Web3JamHQPublic {
        // whitelisted controller accounts
        access(contract) var whitelistedAccounts: {Web3JamInterfaces.WhiteListKey: [Address]}
        // current opening campaign ids
        access(self) var openingCampaigns: [Web3JamInterfaces.CampaignIdentitier]

        init(_ admin: Address) {
            self.whitelistedAccounts = {}
            self.openingCampaigns = []
        }

        destroy () {
            // TODO
        }

        // get current opening campaign ids
        pub fun getOpeningCampaignIDs(): [Web3JamInterfaces.CampaignIdentitier] {
            return self.openingCampaigns
        }

        // is some address whitedlisted for some white list key
        pub fun isWhitelisted(_ key: Web3JamInterfaces.WhiteListKey, account: Address): Bool {
            return self.whitelistedAccounts[key]!.contains(account)
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