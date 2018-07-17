Require Import VST.floyd.proofauto.
Require Import VST.veric.semax_ext.
Require Import VST.sepcomp.extspec.
Require Import VST.veric.juicy_mem.
Require Import DeepWeb.Free.Monad.Free.
Import MonadNotations.
Require Import DeepWeb.Free.Monad.Common.
Require Import DeepWeb.Free.Monad.Verif.
Import String.

Inductive IO_event : Type -> Type :=
| ERead : IO_event int
| EWrite (c : int) : IO_event unit.

Definition read : M IO_event int := embed ERead.

Definition write (c : int) : M IO_event unit := embed (EWrite c).

Definition IO_itree := M IO_event unit.

(* We need a layer of equivalence to allow us to use the monad laws. *)
Definition ITREE (tr : IO_itree) := EX tr' : _, !!(EquivUpToTau tr tr') &&
  has_ext tr'.

Definition putchar_spec :=
  WITH c : int, k : IO_itree
  PRE [ 1%positive OF tint ]
    PROP ()
    LOCAL (temp 1%positive (Vint c))
    SEP (ITREE (write c ;; k))
  POST [ tint ]
    PROP ()
    LOCAL (temp ret_temp (Vint c))
    SEP (ITREE k).

Definition getchar_spec :=
  WITH k : int -> IO_itree
  PRE [ ]
    PROP ()
    LOCAL ()
    SEP (ITREE (r <- read ;; k r))
  POST [ tint ]
   EX i : int,
    PROP (- two_p 7 <= Int.signed i <= two_p 7 - 1)
    LOCAL (temp ret_temp (Vint i))
    SEP (ITREE (k i)).

Fixpoint write_list l : IO_itree :=
  match l with
  | nil => Ret tt
  | c :: rest => write c ;; write_list rest
  end.

Lemma ITREE_impl : forall tr tr', EquivUpToTau tr tr' ->
  ITREE tr |-- ITREE tr'.
Proof.
  intros.
  unfold ITREE.
  Intros tr1; Exists tr1; entailer!.
  etransitivity; eauto.
  symmetry; auto.
Qed.

Lemma ITREE_ext : forall tr tr', EquivUpToTau tr tr' ->
  ITREE tr = ITREE tr'.
Proof.
  intros; apply pred_ext; apply ITREE_impl; auto.
  symmetry; auto.
Qed.

Opaque bind.

Lemma write_list_app : forall l1 l2,
  EquivUpToTau (write_list (l1 ++ l2)) (write_list l1;; write_list l2).
Proof.
  induction l1; simpl; intros.
  - symmetry; apply leftId.
  - rewrite <- bindAssoc.
    Transparent bind.
    simpl.
    apply cong_bind; [reflexivity|].
    intro; apply IHl1.
Qed.

Definition char0 : Z := 48.
Definition newline := 10.

(* Build the external specification. *)
Definition void_spec T :=
    Build_external_specification
      juicy_mem external_function T
      (fun ef => False)
      (fun ef Hef ge tys vl m z => False)
      (fun ef Hef ge ty vl m z => False)
      (fun rv m z => False).

Definition ok_void_spec (T : Type) : OracleKind.
 refine (Build_OracleKind T (Build_juicy_ext_spec _ (void_spec T) _ _ _)).
Proof.
  simpl; intros; contradiction.
  simpl; intros; contradiction.
  simpl; intros; intros ? ? ? ?; contradiction.
Defined.

Definition IO_specs (ext_link : string -> ident) :=
  [(ext_link "putchar"%string, putchar_spec); (ext_link "getchar"%string, getchar_spec)].

Definition IO_ext_spec ext_link :=
  semax_ext.add_funspecs_rec
    ext_link
    (ok_void_spec IO_itree).(@OK_ty)
    (ok_void_spec IO_itree).(@OK_spec)
    (IO_specs ext_link).
