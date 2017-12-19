(**************************************************************************)
(*                                                                        *)
(*    Copyright (c) 2017 - OCamlPro SAS                                   *)
(*                                                                        *)
(*    All rights reserved. No warranty, explicit or implicit, provided.   *)
(*                                                                        *)
(**************************************************************************)

exception RequestError of string

type from =
  | From_string of string
  | From_file of string

(** Run contract with given parameter and storage on the Tezos node specified
   in ![LiquidOptions], returns a pair containig the return value and the
   storage *)
val run : from -> string -> string -> LiquidTypes.const * LiquidTypes.const

(** Forge a deployment operation contract on the Tezos node specified in
   ![LiquidOptions], returns the hex-encoded operation *)
val forge_deploy : from -> string list -> string

(** Deploy a Liquidity contract on the Tezos node specified in
   ![LiquidOptions], returns the operation hash and the contract address *)
val deploy : from -> string list -> string * string

val get_storage : from -> string -> LiquidTypes.const

(** Forge an operation to call a deploy contract, returns the hex-encoded
   operation *)
val forge_call : from -> string -> string -> string

(** Calls a deployed Liquidity contract on the Tezos node specified in
   ![LiquidOptions], returns the operation hash *)
val call : from -> string -> string -> string
