library MNMLibrary {
    // types
    struct Profile {
        // validator id
        uint64 vId;
        // client address
        address client;
        // validator profile
        string profile;
        // validator point
        uint256 point;
    }
    // state
    struct MNMState {
        // priority of validators
        uint64[] priority;
        // validator profile
        mapping (uint64 => Profile) profileOf;
        // random forest
        uint256 forest;
        // point balances
        mapping (uint64 => uint256) pointOf;
        // total points
        uint256 totalPoints;
        // validator limit
        uint64 vLimit;
    }

    // events

    // functions
    function _stake(MNMState storage self, uint64 vId, uint256 point) internal {
        // stake to the validator id, add point to the validator profile
        self.pointOf[vId] += point;
        // adjust the priority of the validator

    }

    function _unstake(MNMState storage self, uint64 vId, uint256 point) internal {
        // unstake from the validator id, subtract point from the validator profile
        self.pointOf[vId] -= point;
        // adjust the priority of the validator

    }
}

