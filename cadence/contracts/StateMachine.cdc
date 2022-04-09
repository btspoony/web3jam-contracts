/**

Finite State Machine
*/

pub contract StateMachine {

    /**    ____ _  _ ____ _  _ ___ ____
       *   |___ |  | |___ |\ |  |  [__
        *  |___  \/  |___ | \|  |  ___]
         ******************************/

    // emitted when contract initialized
    pub event ContractInitialized()
    // emitted when state entered
    pub event StateEntered(fsmOwner: Address, fsmId: UInt64, targetIdentifier: String, state: String)
    // emitted when state exited
    pub event StateExited(fsmOwner: Address, fsmId: UInt64, targetIdentifier: String, state: String)

    /**    ____ _  _ _  _ ____ ___ _ ____ _  _ ____ _    _ ___ _   _
       *   |___ |  | |\ | |     |  | |  | |\ | |__| |    |  |   \_/
        *  |    |__| | \| |___  |  | |__| | \| |  | |___ |  |    |
         ***********************************************************/

    // An interface that every "verifier" must implement. 
    // A verifier is one of the options 
    // for example, a "time limit," or a "limited" number
    // All the current verifiers can be seen inside Web3JamVerifiers.cdc
    pub struct interface IVerifier {
        // A function every verifier must implement. 
        // Will have `assert`s in it to make sure
        // the user fits some criteria.
        access(account) fun verify(_ params: {String: AnyStruct})
    }

    // An interface that every "checker" must implement. 
    pub struct interface IChecker {
        access(account) fun check(_ params: {String: AnyStruct}): Bool
    }

    // An interface that every "action" must implement. 
    pub struct interface IAction {
        access(account) fun execute(_ params: {String: AnyStruct})
    }

    // record state changing log
    pub struct StateLog {
        pub let state: String
        pub let datetime: UFix64

        init(_ state: String, _ datetime: UFix64) {
            self.state = state
            self.datetime = datetime
        }
    }

    // result of FSM's checkNext method

    pub struct CheckResult {
        pub let changed: Bool
        pub let next: String?

        init(_ changed: Bool, _ next: String?) {
            self.changed = changed
            self.next = next
        }
    }

    // FSM transition
    pub struct StateTransition {
        pub let next: String
        pub let check: {IChecker}
        pub let enterActions: [{IAction}]
        pub let exitActions: [{IAction}]
        
        init(next: String, check: {IChecker}, enterActions: [{IAction}]?, exitActions: [{IAction}]?) {
            self.next = next
            self.check = check
            self.enterActions = enterActions ?? []
            self.exitActions = exitActions ?? []
        }
    }

    // FSM state definition
    pub struct StateDefinition {
        pub let name: String
        pub let transitions: [StateTransition]

        init(_ name: String, transitions: [StateTransition]) {
            self.name = name
            self.transitions = transitions
        }
    }

    // Interface of a FSM
    pub resource interface IFiniteStateMachine {
        // ------ constants ------
        pub let targetIdentifier: String
        pub let states: {String: StateDefinition}

        // ------ varibles ------
        pub var currentState: String
        pub var lastState: String?
        access(account) var stateLogs: [StateLog]
        
        // ------ methods ------
        pub fun checkNext(_ params: {String: AnyStruct}): CheckResult
        access(account) fun executeNext(_ params: {String: AnyStruct})
    }

    // FSM resource
    pub resource FSM: IFiniteStateMachine {
        // ------ constants ------
        // traget identifier of FSM
        pub let targetIdentifier: String
        // states of FSM
        pub let states: {String: StateDefinition}

        // ------ varibles ------
        // current FSM state
        pub var currentState: String
        // last FSM state
        pub var lastState: String?
        // state logs
        access(account) var stateLogs: [StateLog]
        
        // ------ methods ------
        // check if fsm will go to next state 
        pub fun checkNext(_ params: {String: AnyStruct}): CheckResult {
            // TODO
            return CheckResult(false, nil)
        }

        // execute state machine to next state 
        access(account) fun executeNext(_ params: {String: AnyStruct}) {
            // TODO
        }

        // initialize
        init(_ targetIdentifier: String, states: {String: StateDefinition}, start: String) {
            pre {
                states[start] != nil: "There is no start state in states definition."
            }
            self.targetIdentifier = targetIdentifier
            self.states = states
            self.currentState = start
            self.lastState = nil
            self.stateLogs = [StateLog(start, getCurrentBlock().timestamp)]
        }
    }

    // ------- utility methods -------

    // convert struct array to a typed dictionary
    access(account) fun buildTypedStructs(_ array: [AnyStruct]): {String: [AnyStruct]} {
        let typed: {String: [AnyStruct]} = {}
        for one in array {
            let identifier = one.getType().identifier
            if typed[identifier] == nil {
                typed[identifier] = [one]
            } else {
                typed[identifier]!.append(one)
            }
        }
        return typed
    }

    init() {
        emit ContractInitialized()
    }
}