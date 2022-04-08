/**

Web3Jam verifiers
*/
import Web3JamInterfaces from "./Web3JamInterfaces.cdc"

pub contract Web3JamVerifiers {

    //
    // Timelock
    //
    // Specifies a time range in which
    // `verify` is valid
    pub struct Timelock: Web3JamInterfaces.IVerifier {
        // An automatic switch handled by the contract
        // to stop people from claiming after a certain time.
        pub let dateStart: UFix64
        pub let dateEnding: UFix64

        pub fun verify(_ params: {String: AnyStruct}) {
            assert(
                getCurrentBlock().timestamp >= self.dateStart,
                message: "not started yet."
            )
            assert(
                getCurrentBlock().timestamp <= self.dateEnding,
                message: "Sorry! The time has run out to mint this FLOAT."
            )
        }

        init(_ timePeriod: UFix64, _ dateStart: UFix64?) {
            // setup data
            if dateStart != nil {
                self.dateStart = dateStart!
            } else {
                self.dateStart = getCurrentBlock().timestamp
            }
            self.dateEnding = self.dateStart + timePeriod
        }
    }

}