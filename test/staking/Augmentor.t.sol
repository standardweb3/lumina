pragma solidity >=0.8;

import {console} from "forge-std/console.sol";
import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";
import {MockToken} from "../../contracts/mock/MockToken.sol";
import {MockBase} from "../../contracts/mock/MockBase.sol";
import {MockQuote} from "../../contracts/mock/MockQuote.sol";
import {MockBTC} from "../../contracts/mock/MockBTC.sol";
import {ErrToken} from "../../contracts/mock/MockTokenOver18Decimals.sol";
import {Utils} from "../utils/Utils.sol";
import {MatchingEngine} from "../../contracts/safex/MatchingEngine.sol";
import {OrderbookFactory} from "../../contracts/safex/orderbooks/OrderbookFactory.sol";
import {Orderbook} from "../../contracts/safex/orderbooks/Orderbook.sol";
import {ExchangeOrderbook} from "../../contracts/safex/libraries/ExchangeOrderbook.sol";
import {IOrderbookFactory} from "../../contracts/safex/interfaces/IOrderbookFactory.sol";
import {WETH9} from "../../contracts/mock/WETH9.sol";
import {Treasury} from "../../contracts/sabt/Treasury.sol";

contract BaseSetup is Test {
    Utils public utils;
    MatchingEngine public matchingEngine;
    WETH9 public weth;
    OrderbookFactory public orderbookFactory;
    Orderbook public book;
    MockBase public token1;
    MockQuote public token2;
    MockBTC public btc;
    MockToken public feeToken;
    Treasury public treasury;
    address payable[] public users;
    address public trader1;
    address public trader2;
    address public booker;
    address public attacker;
    address public augmentor;

    function setUp() public virtual {
        utils = new Utils();
        users = utils.createUsers(4);
        trader1 = users[0];
        vm.label(trader1, "Trader 1");
        trader2 = users[1];
        vm.label(trader2, "Trader 2");
        booker = users[2];
        vm.label(booker, "Booker");
        attacker = users[3];
        vm.label(attacker, "Attacker");
        token1 = new MockBase("Base", "BASE");
        token2 = new MockQuote("Quote", "QUOTE");
        btc = new MockBTC("Bitcoin", "BTC");
        weth = new WETH9();

        token1.mint(trader1, 10000000e18);
        token2.mint(trader1, 10000000e18);
        btc.mint(trader1, 10000000e18);
        token1.mint(trader2, 10000000e18);
        token2.mint(trader2, 10000000e18);
        btc.mint(trader2, 10000000e18);
        feeToken = new MockToken("Fee Token", "FEE");
        feeToken.mint(booker, 40000e18);
        matchingEngine = new MatchingEngine();
        orderbookFactory = new OrderbookFactory();
        orderbookFactory.initialize(address(matchingEngine));
        treasury = new Treasury();
        treasury.set(address(0), address(0), address(0));
        matchingEngine.initialize(
            address(orderbookFactory),
            address(treasury),
            address(weth)
        );

        vm.prank(trader1);
        token1.approve(address(matchingEngine), 10000000e18);
        vm.prank(trader1);
        token2.approve(address(matchingEngine), 10000000e18);
        vm.prank(trader1);
        btc.approve(address(matchingEngine), 10000000e18);
        vm.prank(trader2);
        token1.approve(address(matchingEngine), 10000000e18);
        vm.prank(trader2);
        token2.approve(address(matchingEngine), 10000e18);
        vm.prank(trader2);
        btc.approve(address(matchingEngine), 10000e8);
        vm.prank(booker);
        feeToken.approve(address(matchingEngine), 40000e18);
    }
}

contract StakeTest is BaseSetup {
    function setUp() public override {
        super.setUp();
    }

    function testRevertWhenStakePairDoNotExist() public {
    }

    function testCheckAccountBeforeStaking() public {}
    
    function testStakeAndAugmentAssetAppear() public {

    }

    function testStakeAndAugmentAssetNotAppearOnOversupply() public {

    }

    function testStake() public {
        // stake 1000 token1
        // check point balance
        // check token1 balance
        // check total supply
        // check total staked
        // check total point supply
        // check total point staked
        // check total point burned
        // check total point minted
        // check total point claimed
        // check total point unclaimed
        // check total point locked
    }
}