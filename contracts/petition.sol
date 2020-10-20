pragma solidity >=0.5.17 <=0.7.4;
pragma experimental ABIEncoderV2;

// Caller
contract Petition{
  // 국민 청원 내용
  struct Content {
    string title;
    string content;
    string[] tags;
    uint256 vote;
    uint256 start_time;
    string reply_url;
    bool is_replied;
    string category;
    bool is_block;
    string blocked_reason;
  }

  struct JuryPanel {
    uint256[] blocking_list;
    uint256 dislike;
    uint256 like;
  }

  address owner;  // 청원 관리자
  uint256 id;  // 청원 index
  uint256 NUM_JURY;
  mapping(bytes32=>bool) votecheck;  // 해당 청원에 vote 했는지 여부 저장
  mapping(bytes32=>bool) juryvotecheck;
  mapping(uint256=>Content) petitions;  // 청원 저장
  mapping(address=>JuryPanel) jury_panels;
  address[] jury_address;
  bool debugmode;
  uint[] return_indexes;

  modifier isJuryPanel() {
    // emit Alert(msg.sender, functionname);
    require(jury_panels[msg.sender].like == 0 && jury_panels[msg.sender].dislike == 0, "msg.sender is not a jury pannel.");
    require(jury_panels[msg.sender].dislike > 100, "This jury panel has over 100 dislikes.");
    _;
  }

  modifier voteChecker(uint256 _id) {  // 사용자가 이미 투표를 했는지 확인
    bytes32 addrhash = keccak256(toBytes(msg.sender));
    bytes32 idhash = keccak256(abi.encodePacked(_id));
    bytes32 checkhash = keccak256(abi.encodePacked(addrhash ^ idhash));
    require(!votecheck[checkhash], "This petition is already voted by msg.sender");
    votecheck[checkhash] = true;
    _;
  }

    modifier juryvoteChecker(address jury) {  // 사용자가 이미 투표를 했는지 확인
    require(jury_panels[jury].like == 0 && jury_panels[jury].dislike == 0, "The jury does not exist.");
    bytes32 senderhash = keccak256(toBytes(msg.sender));
    bytes32 juryhash = keccak256(toBytes(jury));
    bytes32 checkhash = keccak256(abi.encodePacked(juryhash ^ senderhash));
    require(!juryvotecheck[checkhash], "This jury is already evaluated by msg.sender");
    juryvotecheck[checkhash] = true;
    _;
  }

  modifier isOwner() {  // 청원 관리자 확인
    if(!debugmode){
      require(msg.sender == owner, "msg.sender is not the owner");
    }
    _;
  }

  constructor() public{
    owner = msg.sender;
    debugmode = true;
    NUM_JURY = 0;
    id = 0;
  }

  function applyJury() public{
    require(NUM_JURY > 100, "No vacancy for jury panel");
    jury_panels[msg.sender].dislike = 1;
    jury_panels[msg.sender].like = 1;
    jury_address.push(msg.sender);
  }

  function blockingContent(uint256 _id, string memory _blocked_reason) public isJuryPanel() {
    petitions[_id].is_block = true;
    petitions[_id].blocked_reason = _blocked_reason;
    jury_panels[msg.sender].blocking_list.push(_id);
  }

  function vote(uint256 _id) public voteChecker(_id) {  // 투표하기, did&중복투표 체크함
    petitions[_id].vote += 1;
  }

  function write(string memory title, string memory content, string[] memory tags) public {  // 청원 작성
    petitions[id].title = title;
    petitions[id].content = content;
    for (uint i = 0; i < tags.length; i++){
      petitions[id].tags.push(tags[i]);
    }
    petitions[id].vote = 0;
    petitions[id].start_time = block.timestamp;
    petitions[id].is_replied = false;
    id++;
  }

  function debugmodectl(bool mode) public{
    debugmode = mode;
  }

  function viewContent(uint256 _id) external view returns(Content memory) {  // 청원 내용 불러오기
    require(_id < id, "doesn't exist.");
    return petitions[_id];
  }


  function getContentsList(bool _is_all, bool _is_replied, bool _is_public, bool _is_block) external returns(Content[] memory) {  // 청원 list 불러오기
    // 가져올 인덱스 계산하기
    if (_is_all){
      Content[] memory list = new Content[](id);
      for(uint i = 0; i < id; i++){
        list[i].title = petitions[i].title;
        list[i].content = petitions[i].content;
        list[i].vote = petitions[i].vote;
        list[i].tags = petitions[i].tags;
        list[i].start_time = petitions[i].start_time;
        list[i].reply_url = petitions[i].reply_url;
        list[i].is_replied = petitions[i].is_replied;
        list[i].category = petitions[i].category;
        list[i].is_block = petitions[i].is_block;
        list[i].blocked_reason = petitions[i].blocked_reason;
      }
      return list;
    }
    else{
      for(uint i = 0; i < id; i++){
        if (petitions[i].is_replied == _is_replied && (petitions[i].vote > 100) == _is_public && petitions[i].is_block == _is_block)
          return_indexes.push(i);
    }
    // 가져올 인덱스에 해당하는 글 array에 추가하기
    uint length = return_indexes.length;
    Content[] memory list = new Content[](length);
    for(uint i = 0; i < length; i++){
      uint _index = return_indexes[i];
      list[i].title = petitions[_index].title;
      list[i].content = petitions[_index].content;
      list[i].vote = petitions[_index].vote;
      list[i].tags = petitions[_index].tags;
      list[i].start_time = petitions[_index].start_time;
      list[i].reply_url = petitions[_index].reply_url;
      list[i].is_replied = petitions[_index].is_replied;
      list[i].category = petitions[_index].category;
      list[i].is_block = petitions[_index].is_block;
      list[i].blocked_reason = petitions[_index].blocked_reason;
    }
    delete return_indexes;
    return list;
    }
  }

  function getLastIndex() external view returns(uint256) {  // 마지막 index 보기
    return id - 1;
  }

  function reply(uint256 _id, string memory url) public isOwner()  {  // 청원에 답변한 url 달기
    petitions[_id].reply_url = url;
    petitions[_id].is_replied = true;
  }

  function toBytes(address addr) private pure returns(bytes memory) {  // address type을 bytes type으로 바꾸기 (hashing 용)
    bytes memory byteaddr = new bytes(20);
    for (uint8 i = 0; i < 20; i++) {
      byteaddr[i] = byte(uint8(uint(addr) / (2**(8*(19 - i)))));
    }
    return (byteaddr);
  }

  function evaluateJury(address jury, bool isLike) public juryvoteChecker(jury) {
    if (isLike) jury_panels[jury].like++;
    else {
      jury_panels[jury].dislike++;
      if (jury_panels[jury].dislike > 100) {
        delete jury_panels[jury];
        NUM_JURY--;

        for (uint i = 0; i < jury_address.length; i++){
          if (jury_address[i] == jury) {
            delete jury_address[i];
            break;
          }
        }
      }
    }
  }

  function getJuryList() external view returns(JuryPanel[] memory) {  // 판정단 list 불러오기
    JuryPanel[] memory list = new JuryPanel[](NUM_JURY);
    for(uint i = 0; i < jury_address.length; i++){
      if(jury_address[i] != address(0x0)){
        list[i].dislike = jury_panels[jury_address[i]].dislike - 1;
        list[i].like = jury_panels[jury_address[i]].like - 1;
        list[i].blocking_list = jury_panels[jury_address[i]].blocking_list;
      }
    }
    return list;
  }
}