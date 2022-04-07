/**

Web3Jam contract interfaces or structs
*/

pub contract Web3JamInterfaces {

    // enum for Web3Jam HQ whitelist
    pub enum WhiteListKey: UInt8 {
        pub case fullControl
    }

    // a wrapper to contain a address, campaign id
    pub struct CampaignIdentitier {
        pub let id: UInt64
        pub let address: Address

        init (
            _ id: UInt64,
            _ address: Address
        ) {
            self.id = id
            self.address = address
        }
    }

    /**    _ _  _ ___ ____ ____ ____ ____ ____ ____ 
       *   | |\ |  |  |___ |__/ |___ |__| |    |___ 
        *  | | \|  |  |___ |  \ |    |  | |___ |___ 
         *******************************************/

    // Web3JamHQ Public Interface
    pub resource interface Web3JamHQPublic {
        pub fun getOpeningCampaignIDs(): [CampaignIdentitier]
        pub fun isWhitelisted(_ key: WhiteListKey, account: Address): Bool
    }

}