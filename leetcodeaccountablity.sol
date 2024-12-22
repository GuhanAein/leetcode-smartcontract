// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LeetCodeAccountability {
    struct Challenge {
        address participant;
        address friendAccount;
        uint256 deadline;
        uint256 stakedAmount;
        bool completed;
        bool verified;
    }

    mapping(uint256 => Challenge) public challenges;
    uint256 public challengeCounter;

    event ChallengeCreated(
        uint256 challengeId, 
        address participant, 
        address friendAccount, 
        uint256 deadline, 
        uint256 stakedAmount
    );
    event ChallengeCompleted(uint256 challengeId);
    event FundsDisbursed(uint256 challengeId, address recipient, uint256 amount);

    function createChallenge(
        address _friendAccount, 
        uint256 _deadlineTimestamp
    ) public payable {
        require(msg.value > 0, "Must stake some ETH");
        
        challengeCounter++;
        challenges[challengeCounter] = Challenge({
            participant: msg.sender,
            friendAccount: _friendAccount,
            deadline: _deadlineTimestamp,
            stakedAmount: msg.value,
            completed: false,
            verified: false
        });

        emit ChallengeCreated(
            challengeCounter, 
            msg.sender, 
            _friendAccount, 
            _deadlineTimestamp, 
            msg.value
        );
    }

    function submitProof(uint256 _challengeId) public {
        Challenge storage challenge = challenges[_challengeId];
        
        require(msg.sender == challenge.participant, "Only participant can submit");
        require(block.timestamp <= challenge.deadline, "Deadline passed");

        challenge.completed = true;
        challenge.verified = true;

        emit ChallengeCompleted(_challengeId);
    }

    function disburseFunds(uint256 _challengeId) public {
        Challenge storage challenge = challenges[_challengeId];
        
        require(block.timestamp > challenge.deadline, "Deadline not passed");
        
        address recipient = challenge.completed 
            ? challenge.participant 
            : challenge.friendAccount;

        (bool success, ) = payable(recipient).call{value: challenge.stakedAmount}("");
        require(success, "Transfer failed");

        emit FundsDisbursed(_challengeId, recipient, challenge.stakedAmount);
    }

    receive() external payable {}
}