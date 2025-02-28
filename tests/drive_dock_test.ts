import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test create and book ride flow",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const passenger = accounts.get('wallet_1')!;
    
    // Create ride
    let block = chain.mineBlock([
      Tx.contractCall('drive-dock', 'create-ride', [
        types.uint(2),
        types.ascii("Downtown"),
        types.uint(50000),
        types.principal(deployer.address)
      ], deployer.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Book ride
    block = chain.mineBlock([
      Tx.contractCall('drive-dock', 'book-ride', [
        types.uint(1),
        types.principal(passenger.address)
      ], passenger.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify ride details
    const response = chain.callReadOnlyFn(
      'drive-dock',
      'get-ride',
      [types.uint(1)],
      deployer.address
    );
    
    const ride = response.result.expectOk().expectSome();
    assertEquals(ride['status'].value, "booked");
  }
});

Clarinet.test({
  name: "Test rating system",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const passenger = accounts.get('wallet_1')!;
    
    // Create and book ride
    let block = chain.mineBlock([
      Tx.contractCall('drive-dock', 'create-ride', [
        types.uint(2),
        types.ascii("Downtown"),
        types.uint(50000),
        types.principal(deployer.address)
      ], deployer.address),
      Tx.contractCall('drive-dock', 'book-ride', [
        types.uint(1),
        types.principal(passenger.address)
      ], passenger.address)
    ]);
    
    // Rate ride
    block = chain.mineBlock([
      Tx.contractCall('drive-dock', 'rate-ride', [
        types.uint(1),
        types.uint(5),
        types.ascii("Great service!")
      ], passenger.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Check rating
    const response = chain.callReadOnlyFn(
      'drive-dock',
      'get-user-rating',
      [types.principal(deployer.address)],
      deployer.address
    );
    
    response.result.expectOk().expectUint(5);
  }
});
