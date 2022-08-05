// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract IDManagementSystem{

    //--------------------------------------------------------------Initialization--------------------------------------------------------------//
    //audit requests for the auditors
    struct AuditionRequest{
        address owner; // identity owner id
        address documentID; // document id
        address auditor; // auditor id
    }

    //'to-be-verified' requests for the verifier(service provider)
    struct VerificationRequest{
        address owner; 
        address verifier; // verifier id
        bool isVerified; // To check if a document is truly verified
        bool isVerificationRequired; // to check if a document needs verification
    }

    // List of documents uploaded by the owner
    struct Document{
        bool isAudited; // Check if document is audited by the auditor or not
        bool isDeclined; // Check if the document uploaded is declined by the auditor
        string title; // Title of the document uploaded e.g passport, ID card
    }

    struct Owner{
        int256 trustScore; // A score to check the trustworthiness of an identity owner
        mapping(address=>Document) documents;
    }

    //List of identity owners
    mapping(address=>Owner) owners;

    //The list of verification and their respective verifier 
    mapping(uint256=>VerificationRequest) VerificationList;

    //[Temporary]List of auditors
    address[] auditors =[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 , 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2  , 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db];

    // List of all audit requests
    AuditionRequest[] auditionList;

    //--------------------------------------------------------------Functions--------------------------------------------------------------//
    function checkAuditor(address sender) internal view returns(bool){
        for(uint256 i=0;i<auditors.length;++i)
            if( sender == auditors[i])
                return true;
        return false;
    }

    //To check if the person auditing is an actual auditor
    modifier isAuditor(){
        require(checkAuditor(msg.sender),"Caller is not an auditor!");
        _;
    }

    // upload a document request by the identity owner/user
    function uploadDocument(address _documentID , string memory _title) public{
        // initially the document is neither audited nor declined by an auditor
        bool _isAudited = false; 
        bool _isDeclined = false; 

        owners[msg.sender].documents[_documentID]=Document(_isAudited,_isDeclined,_title);
        owners[msg.sender].trustScore = 0; // initially trustScore is zero

        //Request an audit request from 3 random auditors
        auditRequest(msg.sender,_documentID);
    }

    // Audit request for 3 random auditors
    function auditRequest(address _ownerID ,address _documentID) internal {
        for(uint256 i=0;i<3;i++){
            auditionList.push(AuditionRequest(_ownerID,_documentID,random())); // Pick a random auditor to check the uploaded document
        }
    }

    // Helper function - to get a random number
    function random() private view returns(address){
        return auditors[uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp)))%  auditors.length];
    }

    // Auditor function - update the status of the uplaoded document -Declined/Accepted-
    function audit(address _documentID , address _ownerID , bool isApprove, int256 _feedback) public isAuditor{
        //If request is not approved
        if(!isApprove){  
            owners[_ownerID].documents[_documentID].isDeclined=true;
        }
    
        owners[_ownerID].documents[_documentID].isAudited=true;
        owners[_ownerID].trustScore +=_feedback;
    }

    // Verifier function- request identity owner verification
    function verificationRequest(address _ownerID) public  returns (uint256){

        //Algorithm to verify if owner is who claims to be
        uint256 verifierNum = uint256(uint160(address(msg.sender)));
        uint256 senderNum = uint256(uint160(address(_ownerID)));
        uint256 _specialNum=verifierNum + senderNum; // Result-a special number- is physically/manually handed to the identity owner

        // Add information to verificationList
        VerificationList[_specialNum].owner= _ownerID;
        VerificationList[_specialNum].verifier= msg.sender;
        VerificationList[_specialNum].isVerified= false;
        VerificationList[_specialNum].isVerificationRequired= true;

        return _specialNum;
    }

    // Function transacted by the identity owner using the special number provided by the verifier in order to proof ownership
    function verifyOwnership(uint256 spcnum) public{
        if(VerificationList[spcnum].isVerificationRequired && VerificationList[spcnum].owner == msg.sender ){
            VerificationList[spcnum].isVerified=true;
        }
    }
    //--------------------------------------------------------------Get functions--------------------------------------------------------------//
    function getDocument(address _documentID) public view returns (Document memory){
        return owners[msg.sender].documents[_documentID];
    }
    function getVerificationStatus(uint256 spcnum) public view returns (bool){
        return VerificationList[spcnum].isVerified;
    }
    function getTrustScore(address _ownerID) public view returns(int256){
        return owners[_ownerID].trustScore;
    }
}
