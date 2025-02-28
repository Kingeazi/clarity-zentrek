import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test session creation and completion flow",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    // Start new session
    let block = chain.mineBlock([
      Tx.contractCall('zentrek', 'start-session',
        [
          types.ascii("meditation-01"),
          types.ascii("ocean-waves"),
          types.uint(300)
        ],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectOk();
    const sessionId = block.receipts[0].result;
    
    // Complete session
    block = chain.mineBlock([
      Tx.contractCall('zentrek', 'complete-session',
        [sessionId],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify user stats
    const statsResponse = chain.callReadOnlyFn(
      'zentrek',
      'get-user-stats',
      [types.principal(user1.address)],
      user1.address
    );
    
    const stats = statsResponse.result.expectOk().expectTuple();
    assertEquals(stats['total-sessions'], types.uint(1));
    assertEquals(stats['total-minutes'], types.uint(300));
    assertEquals(stats['rewards-earned'], types.uint(3000));
  }
});

Clarinet.test({
  name: "Test invalid session completion",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;
    
    // Try to complete non-existent session
    let block = chain.mineBlock([
      Tx.contractCall('zentrek', 'complete-session',
        [types.ascii("invalid-session")],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(101);
  }
});

Clarinet.test({
  name: "Test double session completion prevention",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;
    
    // Start new session
    let block = chain.mineBlock([
      Tx.contractCall('zentrek', 'start-session',
        [
          types.ascii("meditation-01"),
          types.ascii("ocean-waves"),
          types.uint(300)
        ],
        user1.address
      )
    ]);
    
    const sessionId = block.receipts[0].result;
    
    // Complete session first time
    block = chain.mineBlock([
      Tx.contractCall('zentrek', 'complete-session',
        [sessionId],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Try to complete same session again
    block = chain.mineBlock([
      Tx.contractCall('zentrek', 'complete-session',
        [sessionId],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(101);
  }
});
