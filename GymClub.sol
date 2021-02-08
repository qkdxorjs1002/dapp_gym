pragma solidity ^0.4.13;

contract GymClub {
    
    struct Subscriber {
        // 주소
        address addr;
        // 금액
        uint amount;
        // 구독 시작
        uint startAt;
        // 구독 종료
        uint endAt;
        // 종료 여부
        bool isEnd;
        // 출금 여부
        bool isUnsubscribed;
    }
    
    address public owner;
    uint    public numSubscribers;
    uint    public fee;
    uint    public deadline;
    uint    public monthToSecond;
    
    mapping (uint => Subscriber) public subscribers;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // feePerMonth: 월별 요금, subscribeDeadline: 재갱신 마감 기간
    function GymClub(uint feePerMonth, uint subscribeDeadline) {
        owner = msg.sender;
        numSubscribers = 0;
        fee = feePerMonth;
        deadline = subscribeDeadline;
        monthToSecond = 2629743; // 1 month to Seconds
    }
    
    function checkDeadline() public onlyOwner payable {
        uint idx = 0;
        
        while (idx <= numSubscribers) {
            // 출금이 안됐을 경우
            if (!subscribers[idx].isUnsubscribed) {
                // 현재로부터 구독 종료 + 재갱신 기간이 지났을 경우 true
                subscribers[idx].isEnd = (now >= subscribers[idx].endAt + deadline);
            
                // 종료 여부가 true일 경우 계약 계좌에서 소유자에게 일정 금액 입금
                if (subscribers[idx].isEnd) {
                    if(!owner.send(subscribers[idx].amount)) {
                        revert();
                    }
                    // 출금 여부를 true
                    subscribers[idx].isUnsubscribed = true;
                }
            }
            
            idx++;
        }
    }
    
    function pay(uint month) payable {
        require(msg.value == month * fee);
        
        uint idx = 0;
            
        while (idx <= numSubscribers) {
            // Deadline 이내에 추가 구독할 경우 연장
            if (subscribers[idx].addr == msg.sender && !subscribers[idx].isUnsubscribed) {
                subscribers[idx].amount += msg.value;
                subscribers[idx].endAt += (month * monthToSecond);
                subscribers[idx].isEnd = false;
                
                return ;
            }
            
            idx++;
        }
        
        // 구독자 정보 초기화
        Subscriber sub = subscribers[numSubscribers++];
        sub.addr = msg.sender;
        sub.amount = msg.value;
        sub.startAt = now;
        sub.endAt = sub.startAt + (month * monthToSecond);
        sub.isEnd = false;
        sub.isUnsubscribed = false;
    }
    
    function kill() public onlyOwner {
        
        selfdestruct(owner);
    }

}