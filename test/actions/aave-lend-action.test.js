const {
    ethers
  } = require('hardhat');
const BigNumber = require('bignumber.js');

const TestAaveLendAction = hre.artifacts.require('TestAaveLendAction');

describe('AaveLendActionMixin test', function () {

  const interestRateMode = 2;
  const collaternalToken = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
  const borrowToken = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
  const aCollaternalToken = '0x030bA81f1c18d280636F32af80b9AAd02Cf0854e';

  let aaveLendAction;  
  let farmer;

  before('INIT',async function(){
    aaveLendAction = await TestAaveLendAction.new(interestRateMode,collaternalToken,borrowToken);
    await ethers.getSigners().then((resp) => {
        const accounts = resp;
        farmer = accounts[0].address;
      });
  });
  it('add collaternal',async function(){
    const collaternalAmount = new BigNumber(10 * 1e18);
    await aaveLendAction.addCollaternal(collaternalAmount,{value:collaternalAmount});
    await logBorrowInfo();
  });

  it('remove collaternal',async function(){
    const collaternalAmount = new BigNumber(5 * 1e18);
    await aaveLendAction.removeCollaternal(collaternalAmount);
    await logBorrowInfo();
  });

  it('borrow',async function(){
    const borrowAmount = new BigNumber(5000 * 1e6);
    await aaveLendAction.borrow(borrowAmount);
    await logBorrowInfo();
  });

  it('borrow',async function(){
    const repayAmount = new BigNumber(2000 * 1e6);
    await aaveLendAction.repay(repayAmount);
    await logBorrowInfo();
  });

  async function logBorrowInfo(){
    const borrowInfo = await aaveLendAction.borrowInfo();
    console.log('===========borrow info===========');
    console.log('totalCollateralETH:%s',borrowInfo._totalCollateralETH,);
    console.log('totalDebtETH:%s',borrowInfo._totalDebtETH,);
    console.log('availableBorrowsETH:%s',borrowInfo._availableBorrowsETH,);
    console.log('currentLiquidationThreshol:%s',borrowInfo._currentLiquidationThreshold);
    console.log('ltv:%s',borrowInfo._ltv,);
    console.log('healthFactor:%s',borrowInfo._healthFactor);
    console.log('currentBorrow:%s',await aaveLendAction.getCurrentBorrow());
  }
  
});