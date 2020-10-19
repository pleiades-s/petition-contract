pragma solidity >=0.5.17 <0.7.0;
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
    string blocked_reason
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
  mapping(uint256=>Content) petitions;  // 청원 저장
  mapping(address=>JuryPanel) jury_panels;
  bool debugmode;

  modifier isJuryPanel() {
    emit Alert(msg.sender, functionname);
    require(jury_panels[msg.sender], "msg.sender is not jury pannel");
    require(jury_panels[msg.sender].dislike > 100, "this jury panel's dislike is over 100");
    _;
  }

  modifier voteChecker(uint256 _id) {  // 사용자가 이미 투표를 했는지 확인
    bytes32 addrhash = keccak256(toBytes(msg.sender));
    bytes32 idhash = keccak256(abi.encodePacked(_id));
    bytes32 checkhash = keccak256(abi.encodePacked(addrhash ^ idhash));
    require(!votecheck[checkhash], "already voted here.");
    votecheck[checkhash] = true;
    _;
  }

  modifier isOwner() {  // 청원 관리자 확인
    if(!debugmode){
      require(msg.sender == owner, "he is not owner");
    }
    _;
  }

  constructor() public{
    owner = msg.sender;
    debugmode = true;
    NUM_JURY = 0;
    id = 0;
  }

  function applyJury() {
    require(NUM_JURY < 100, "No vacancy for jury panel");
    JuryPanel memory jury_panel = Info(true, "");
    jury_panels[msg.sender].dislike = 0;
    jury_panels[msg.sender].like = 0;
  }

  function blockingContent(uint256 _id, string _blocked_reason) public isJuryPanel() {
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
    petitions[id].starttime = now;
    petitions[id].isreplied = false;
    id++;
  }

  function debugmodectl(bool mode) public{
    debugmode = mode;
  }

  function viewContent(uint256 _id) external view returns(Content memory) {  // 청원 내용 불러오기
    require(_id < id, "doesn't exist.");
    return petitions[_id];
  }


  function getContentsList(uint param_start, uint param_end) external view returns(Content[] memory) {  // 청원 list 불러오기
    uint _start = param_start;
    uint _end = param_end;

    if(_start > _end) {  // 순서 바뀌었을 때
      uint tmp = _start;
      _start = _end;
      _end = tmp;
    }

    if(_end >= id){  // index 초과 했을 때
      _end = id - 1;
    }

    if(_start < 0){  // index 초과 했을 때
      _start = 0;
    }

    Content[] memory list = new Content[](_end-_start);
    for(uint i = _start; i < _end+1; i++){
      list[i].title = petitions[i].title;
      list[i].vote = petitions[i].vote;
      list[i].tags = petitions[i].tags;
    }
    return list;
  }

  function getLastIndex() external view returns(uint256) {  // 마지막 index 보기
    return id-1;
  }

  function reply(uint256 _id, string memory url) public isOwner()  {  // 청원에 답변한 url 달기
    petitions[_id].reply_url = url;
    petitions[_id].isreplied = true;
  }

  function toBytes(address addr) private pure returns(bytes memory) {  // address type을 bytes type으로 바꾸기 (hashing 용)
    bytes memory byteaddr = new bytes(20);
    for (uint8 i = 0; i < 20; i++) {
      byteaddr[i] = byte(uint8(uint(addr) / (2**(8*(19 - i)))));
    }
    return (byteaddr);
  }
}