[%%version 0.402]

type account = {
  balance : nat;
  allowances : (address, nat) map;
}

type storage = {
  accounts : (address, account) big_map;
  version : nat; (* version of token standard *)
  totalSupply : nat;
  decimals : nat;
  name : string;
  symbol : string;
  owner : address;
}

let%init storage
    (owner : address) (totalSupply : nat) (decimals : nat)
    (name : string) (symbol : string) =
  let owner_account  =
    { balance = totalSupply;
      allowances = (Map : (address, nat) map) } in
  let accounts =
    Map.add owner owner_account (BigMap : (address, account) big_map) in
  {
    accounts;
    version = 1p;
    totalSupply;
    decimals;
    name;
    symbol;
    owner;
  }

let get_account ((a : address), (storage : storage)) =
  match Map.find a storage.accounts with
  | None -> { balance = 0p; allowances = (Map : (address, nat) map) }
  | Some account -> account

let perform_transfer
    ((from : address), (dest : address), (tokens : nat), (storage : storage)) =
  let account_sender = get_account (from, storage) in
  let account_dest = get_account (dest, storage) in
  let new_account_sender = match is_nat (account_sender.balance - tokens) with
    | None ->
      failwith ("Not enough tokens for transfer", account_sender.balance)
    | Some b -> account_sender.balance <- b in
  let new_account_dest =
    account_dest.balance <- account_dest.balance + tokens in
  let accounts = storage.accounts in
  let accounts = Map.add from new_account_sender accounts in
  let accounts = Map.add dest new_account_dest accounts in
  ([] : operation list), storage.accounts <- accounts

let%entry transfer ((dest : address), (tokens : nat)) storage =
  perform_transfer (Current.sender (), dest, tokens, storage)

let%entry approve ((spender : address), (tokens : nat)) storage =
  let account_sender = get_account (Current.sender (), storage) in
  let account_sender =
    account_sender.allowances <-
      Map.add spender tokens account_sender.allowances in
  let storage = storage.accounts <-
      if tokens = 0p then
        Map.remove (Current.sender ()) storage.accounts
      else
        Map.add (Current.sender ()) account_sender storage.accounts in
  ([] : operation list), storage

let%entry transferFrom
    ((from : address), (dest : address), (tokens : nat)) storage =
  let account_from = get_account (from, storage) in
  let new_allowances_from =
    match Map.find (Current.sender ()) account_from.allowances with
    | None -> failwith ("Not allowed to spend from", from)
    | Some allowed ->
      match is_nat (allowed - tokens) with
      | None ->
        failwith ("Not enough allowance for transfer", allowed)
      | Some allowed ->
        if allowed = 0p then
          Map.remove (Current.sender ()) account_from.allowances
        else
          Map.add (Current.sender ()) allowed account_from.allowances in
  let account_from = account_from.allowances <- new_allowances_from in
  let storage = storage.accounts <-
      Map.add from account_from storage.accounts in
  perform_transfer (from, dest, tokens, storage)



(* ------------- Storage access from outside ------------- *)

contract type NatContract = sig
  type storage
  val%entry main : nat -> _
end

contract type NatNatContract = sig
  type storage
  val%entry main : nat * nat -> _
end

let%entry balanceOf
    ((spender : address), (forward : NatContract.instance)) storage =
  let spender_balance = match Map.find spender storage.accounts with
    | None -> 0p
    | Some account -> account.balance in
  [ forward.main spender_balance ~amount:0tz ], storage

let%entry allowance
    ((from : address), (spender : address), (forward : NatNatContract.instance))
    storage =
  let spender_allowance = match Map.find from storage.accounts with
    | None -> 0p, 0p
    | Some account -> match Map.find spender account.allowances with
      | None -> 0p, account.balance
      | Some allowed -> allowed, account.balance in
  [ forward.main spender_allowance ~amount:0tz ], storage


(* -------------- Creating accounts ------------------------ *)

let%entry createAccount ((dest : address), (tokens :nat)) storage =
  if Current.sender () <> storage.owner then
    failwith "Only owner can create accounts";
  perform_transfer (storage.owner, dest, tokens, storage)

let%entry createAccounts (new_accounts : (address * nat) list) storage =
  if Current.sender () <> storage.owner then
    failwith "Only owner can create accounts";
  List.fold (fun ((dest, tokens), (_ops, storage)) ->
      perform_transfer (storage.owner, dest, tokens, storage)
    ) new_accounts (([] : operation list), storage)
