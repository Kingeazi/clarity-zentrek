[Previous test content remains unchanged, new tests added below]

Clarinet.test({
  name: "Test session duration limits",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;
    
    // Try to create session with invalid duration
    let block = chain.mineBlock([
      Tx.contractCall('zentrek', 'start-session',
        [
          types.ascii("meditation-01"),
          types.ascii("ocean-waves"),
          types.uint(8000) // Exceeds max duration
        ],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(104);
  }
});

Clarinet.test({
  name: "Test admin functions",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    // Test reward rate update
    let block = chain.mineBlock([
      Tx.contractCall('zentrek', 'set-reward-rate',
        [types.uint(20)],
        deployer.address
      )
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify unauthorized user cannot update rate
    block = chain.mineBlock([
      Tx.contractCall('zentrek', 'set-reward-rate',
        [types.uint(30)],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(100);
  }
});
