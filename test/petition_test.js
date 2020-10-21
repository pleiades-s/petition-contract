const Petiton = artifacts.require("Petition");

// Account
const contractAddress = "0x390D07B2Af175087F4B91AdA412916Afe898A0B3"; // contract address
const goverment = "0x4016c8Da10cb66AEB15dE2F012391f52F6946C05"; // 정부
const jury = "0x1306D18c1dB7097fDd2E6FCAB9F055120DF816F0"; // 판정단
const user = "0xA0906De8176B1C19746b30d2Ed7FDc8c8626aB66"; // 일반 사용자

contract('Petition', () => {

    let petition = null;
    before(async () => {
        // 배포 컨트랙트 인스턴트 가져오기
        petition = await Petiton.at(contractAddress);
    })

    // 배포 컨트랙트 인스턴스 가져오기
    it('Should get the deployed contract instance properly.', async () => {
        assert(petition.address == contractAddress)
    })

    // 1. 판정단 신청하기
    it("Should apply a jury panel successfully.", async () =>{
        await petition.applyJury();
        const result = await petition.getJuryList();
        console.log(result);
        assert(result != "");
    })

    // 2. 청원글 작성하기
    // 3. 청원 block 하기
    // 4. 청원글 투표하기
    // 5. 청원글 List 보기
    // 6. 판정단 투표하기 / 중복투표 하기
    // 7. 정부가 답변하기 -> 글 리스트 한번 확인해보기
    // 8. 판정단 List 보기
})


