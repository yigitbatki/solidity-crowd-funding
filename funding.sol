//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding{
    mapping(address=>uint) public contributors;
    address public admin;
    uint public noOfContributors;
    uint public minimumContribution;
    uint public deadline;
    uint public goal;
    uint public raisedAmount;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;

    }

    mapping(uint=>Request) public requests;
    uint public numRequests; 


    constructor(uint _goal, uint _deadline){
        goal = _goal;
        deadline = _deadline;
        minimumContribution = 100 wei;
        admin = msg.sender;
    }

    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);
    
    modifier onlyAdmin(){
        require(msg.sender==admin,"only admin may call this function");
        _;
    }

    function contribute() public payable{
        require(block.timestamp<deadline,"deadline has passed");
        require(msg.value>=minimumContribution,"minimum contribution not met");
        if (contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;

        emit ContributeEvent(msg.sender, msg.value);
    }

    receive() payable external{
        contribute();
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
        
    }

    function getRefund() public {
        require(block.timestamp>deadline && raisedAmount <goal);
        require(contributors[msg.sender]>0);
        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        contributors[msg.sender] = 0;
        recipient.transfer(value);
    } 

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin{
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;

        emit CreateRequestEvent(_description, _recipient, _value);
    }

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"You must be a contributor a vote!");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyAdmin{
        require(raisedAmount>=goal);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false,"this request has been completed");
        require(thisRequest.noOfVoters>noOfContributors/2);
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;

        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
}