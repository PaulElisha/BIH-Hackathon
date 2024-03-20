// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/*@title: GetFunded
@author: 
@notice: This project is a platform that allows anyone to raise funds through crowd-vesting. 
@dev: implements */

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract GetFunded is KeeperCompatibleInterface {
   
     address private immutable i_owner;
     uint256 public s_totalFunded;
     address[] private s_verifiers;
     uint256 immutable i_burnFee;

     struct User {
          address uAddress;
          string name;
          string email;
          string id;
          string location;
          uint256 uId;
          bytes32 role;
     }

     uint256 s_userId;
     User[] s_users;

     struct Project {
          address owner;
          uint256 timeCreated;
          uint256 id;
          string title;
          string description;
          string story;
          uint256 duration;
          uint256 fundingAmount;
          uint256 fundingBalance;
          uint256 amountFunded;
          ProjectType Type;
          string image;
          bool isFunded;
          
          string financials;
          address[] investors;
     }

    //  struct ProjectFinancials {
          
    //  }

     Project[] s_projects;
     uint256 s_projectId;

     enum ProjectType {
          Technology,
          Arts,
          Education,
          Food,
          Infrastructure,
          Business
     }

     enum ProjectState {
          Created,
          Pending,
          Verified,
          Funded,
          Canceled
     }

     ProjectState private s_state;

     mapping (address => User) private s_user;
     mapping (uint256 => Project) private s_project;
     mapping (uint256 => address) private s_idToUserAddress;
     mapping (address => bool) private s_isVerifier;
     mapping (uint => mapping(address => uint)) private s_investorsBalance;
     mapping (address => bool) private s_hasInvested;
     mapping (uint256 => bool) activeProject;

     error InvalidUser();
     error NotVerifier();
     error AlreadyRegistered();
     error ProjectExists();
     error ZeroAddressUnAuthorized();
     error UnAuthorized();
     error NotInvested();
     error UpkeepNeeded();
     error NotActive();
     error TimeNotReached();
     error reachedGoal();


     event Created(
          address indexed projectOwner,
          string title,
          uint256 blockTimeStamp,
          uint256 amount 
     );

     event Registered(
          address indexed user
     );

     event Funded(
          uint256 indexed id,
          address indexed owner,
          uint256 indexed fundingAmount
     );

     event Refunded(
          address investor_,
          uint256 balance
     );
     
     constructor(address[] memory _verifiers, string memory _role) {
          i_owner = msg.sender;

          for(uint256 i = 0; i <= _verifiers.length; i = i + 1) {
              User storage user = s_user[_verifiers[i]];
              user.role = keccak256(abi.encodePacked(_role));
              s_isVerifier[_verifiers[i]] = true;
              s_verifiers.push(_verifiers[i]);
          }
     }

     modifier onlyOwner() {
          if (
               i_owner != msg.sender
          ) revert InvalidUser();
          if (
               i_owner == address(0)
          ) revert InvalidUser();
          _;
     }

     modifier onlyUser() {
          if (
               s_user[msg.sender].uAddress != msg.sender
          ) revert InvalidUser();
          if (
               msg.sender == address(0)
          ) revert InvalidUser();
          _;
     }

     modifier onlyVerifier(uint256 id) {
          if (
               s_isVerifier[s_idToUserAddress[id]] = false
          ) revert NotVerifier();
          _;
     }

     function  getProjects() external view returns (Project[] memory) {
          return s_projects;
     }

     function getProjectById(uint256 id) public view returns (Project memory) {
          return s_project[id];
     }

     function removeProject(uint256 id) external onlyOwner {
          delete id;
     }

     function totalFunded() external view returns (uint256) {
          return s_totalFunded;
     }

    //  function _getCurrentTimestamp() internal view returns (uint48 currentTime) {
    //       currentTime = Time.timestamp();
    //  }

     function getInvestors(uint256 id) external view returns (address[] memory) {
          Project storage project = s_project[id];
          return project.investors;
     }

     function getUsers() external view returns (User[] memory) {
          return s_users;
     }

     function getInvestorsBalance(uint256 _projectid) external view returns (uint256 bal) {
          bal = s_investorsBalance[_projectid][msg.sender];
     }

     function setVerifier(string memory _role, uint256 id) public onlyOwner {
          User storage user = s_user[s_idToUserAddress[id]];
          user.role = keccak256(abi.encodePacked(_role));
          s_verifiers.push(s_idToUserAddress[id]);
          s_isVerifier[s_idToUserAddress[id]] = true;
     }

     function getActiveProjects() external view returns (uint256 id) {
          for(uint256 i = 0; i < s_projects.length; i++) {
               Project storage project = s_projects[i];
               if(activeProject[project.id]) {
                    id = project.id;
               }
          }
          return id;
     }

     function registerUser(User calldata _user) external {
          User storage user = s_user[msg.sender];

          if (
               s_user[msg.sender].uAddress == msg.sender
          ) revert AlreadyRegistered();

          user.uAddress = msg.sender;
          user.name = _user.name;
          user.email = _user.email;
          user.id = _user.id;
          user.location = _user.location;

          user.uId = s_userId + 1;
          s_idToUserAddress[user.uId] = msg.sender;

          s_users.push(user);

          emit Registered (
               msg.sender
          );
     }

     function createProject(Project calldata _project) external onlyUser returns(uint256){
          Project storage project = s_project[s_projectId];

          if(
               activeProject[project.id]
          ) revert ProjectExists();

          if(
               msg.sender == address(0)
          ) revert ZeroAddressUnAuthorized();

          if(
               s_isVerifier[msg.sender]
          ) revert UnAuthorized();

          project.title = _project.title;
          project.description = _project.description;
          project.owner = msg.sender;
          project.story = _project.story;
          project.timeCreated = block.timestamp;
          project.duration = _project.duration;
          project.fundingAmount = _project.fundingAmount;
          project.Type = _project.Type;
          project.image = _project.image;
          project.isFunded = false;
          project.financials = _project.financials;

          project.id = s_projectId + 1;

          s_status = ProjectState.Pending;

          activeProject[project.id] = true;

          s_projects.push(project);

          return project.id;

        //   emit Created (
        //        msg.sender,
        //        project.title,
        //        project.timeCreated,
        //        project.fundingAmount
        //   );
     }

     function fundProject(
        uint _projectid
     ) public payable onlyUser {
          Project storage project = s_project[_projectid];


          if(
               block.timestamp > project.duration
          ) revert NotActive();

          if(
               !s_hasInvested[msg.sender]
          ) revert NotInvested();

          if(
               s_isVerifier[msg.sender]
          ) revert UnAuthorized();

          if(project.fundingBalance == 0) {
               project.isFunded = true;
               activeProject[project.id] = false;
          }

          project.amountFunded += msg.value;
          project.fundingBalance = project.fundingAmount - msg.value;
          s_investorsBalance[_projectid][msg.sender] += msg.value;
          project.investors.push(msg.sender);
          s_hasInvested[msg.sender] = true;

          emit Funded (
               _projectid,
               msg.sender,
               msg.value
          );
     }

     function refundInvestors(
          uint _projectid
     ) external onlyOwner returns(bool sent) {
          Project storage project = s_project[_projectid];

          if(
            project.duration > block.timestamp
          ) revert TimeNotReached();

          if(
            project.fundingBalance > project.fundingAmount
          ) revert reachedGoal();

          if(
            !s_hasInvested[msg.sender]
          ) revert UnAuthorized();

          for (uint i = 0; i < project.investors.length; i++) {
            if (s_hasInvested[project.investors[i]]) {
               address investor = project.investors[i];
               uint userBalance = s_investorsBalance[_projectid][investor];
               s_investorsBalance[_projectid][investor] -= userBalance;
               project.amountFunded -= userBalance;
               (bool success, ) = payable(investor).call{value: userBalance}("");
               s_hasInvested[project.investors[i]] = false;
               require(success);
            }
          }

          project.isFunded = false;
          s_status = ProjectState.Canceled;
          activeProject[_projectid] = false;
          
        //   emit Refunded (
        //        investor,
        //        userBalance
        //   );

          sent = true;
          require(sent);
     }

     function _getFundedProjects() internal view returns (uint256 id, bytes data) {
          for(uint256 i = 0; i < s_projects.length; i++) {
               Project storage project = s_projects[i];
               if(
                    !activeProject[project.id] && 
                    project.isFunded && 
                    project.fundingBalance == 0
               ) {
                    id = project.id;
               }
          }
          return id;
     }

     function checkUpkeep(
          bytes memory /* checkData*/
     ) public override returns(bool upkeepNeeded, bytes memory /* performData */) {
          (id, )= _getFundedProjects();
          Project storage project = s_project[id];
          bool isCreated = ProjectState.Created == s_status;
          bool isVerified = ProjectState.Verified == s_status;
          bool hasInvestors = (project.investors.length > 0);
          bool goalReached = (project.amountFunded == project.fundingAmount);
          bool funded = project.isFunded;
          upkeepNeeded = (
               isCreated && 
               isVerified && 
               goalReached && 
               hasInvestors
          ); 
     }    

     /// Pay Project Creators
     function performUpkeep(
          bytes calldata /* performData */
     ) external override {
          (bool upkeepNeeded, ) = checkUpkeep("");

          if(!upkeepNeeded) revert UpkeepNeeded();
          
          (id, )= _getFundedProjects();

          Project storage project = s_project[id];

          if(!project.isActive[id]) return NotActive();
          if(
               project.fundingBalance == 0
          ) {
               address owner = project.owner;
               uint256 bal = project.amountFunded;
               bal = 0;
               (bool success,) = payable(owner).call{value: bal}("");
               project.isActive[id] = false;
               require(success);
          }
     }

     function payProjectCreator(uint _projectid) external onlyOwner returns (bool sent) {
          Project storage project = s_project[_projectid];

          if(!project.isActive[_projectid]) return NotActive();
          if(
               project.fundingBalance == 0
          ) {
               address owner = project.owner;
               project.amountFunded = 0;
               uint256 bal = project.fundingBalance;
               (success,) = payable(owner).call{value: bal}("");
               project.isActive[_projectId] = false;
               require(success);
          }
          sent = true;
          require(sent);
     }
}