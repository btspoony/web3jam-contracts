/**

Web3Jam Main contract
*/
pub contract Web3Jam {

    /**    ___  ____ ___ _  _ ____
       *   |__] |__|  |  |__| [__
        *  |    |  |  |  |  | ___]
         *************************/

    pub let CampaignsManagerStoragePath: StoragePath
    pub let CampaignsManagerPublicPath: PublicPath

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

    /**    _ _  _ ___ ____ ____ ____ ____ ____ ____ 
       *   | |\ |  |  |___ |__/ |___ |__| |    |___ 
        *  | | \|  |  |___ |  \ |    |  | |___ |___ 
         *******************************************/

    // CampaignsManager Public Interface
    pub resource interface CampaignsManagerPublic {
        pub fun getIDs(): [UInt64]
    }

    /**    ____ _  _ _  _ ____ ___ _ ____ _  _ ____ _    _ ___ _   _
       *   |___ |  | |\ | |     |  | |  | |\ | |__| |    |  |   \_/
        *  |    |__| | \| |___  |  | |__| | \| |  | |___ |  |    |
         ***********************************************************/

    // Campaign
    pub resource Campaign {

        init() {

        }
    }

    // Campaigns manager
    pub resource CampaignsManager: CampaignsManagerPublic {

        access(contract) var whitelisted: [Address]
        access(account) var campaigns: @{UInt64: Campaign}


        pub fun getIDs(): [UInt64] {
            return self.campaigns.keys
        }

        init(_ admin: Address) {
            self.whitelisted = [ admin ]
            self.campaigns <- {}
        }

        destroy () {
            destroy self.campaigns
        }
    }

    init() {
        self.totalCompaigns = 0
        
        // Set the named paths
        self.CampaignsManagerStoragePath  = /storage/Web3JamCampaignsManager
        self.CampaignsManagerPublicPath = /public/Web3JamCampaignsManager

        // Create an manager resource and save it to storage
        self.account.save(
            <- create CampaignsManager(self.account.address),
            to: self.CampaignsManagerStoragePath
        )

        // create a public capability for the manager resource
        self.account.link<&Web3Jam.CampaignsManager{Web3Jam.CampaignsManagerPublic}>(
            self.CampaignsManagerPublicPath,
            target: self.CampaignsManagerStoragePath
        )

        emit ContractInitialized()
    }
}