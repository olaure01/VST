Require Import floyd.base.
Require Import floyd.client_lemmas.
Require Import floyd.type_induction.
Require Import floyd.jmeq_lemmas.
Require Import Coq.Logic.JMeq.

(******************************************

Definition of reptype.

******************************************)

Notation sigTT P := (fun tv => match tv with existT t v => P t end).

Definition compact_prod_sigT_type {A} {P: A -> Type} (l: list (sigT P)): Type :=
  compact_prod (map (sigTT P) l).

Definition compact_prod_sigT_value: forall {A} {P: A -> Type} (l: list (sigT P)), compact_prod (map (sigTT P) l).
Proof.
  intros.
  destruct l as [| [t0 v0] l]; [exact tt |].
  revert t0 v0; induction l as [| [t v] l]; intros.
  + exact v0.
  + exact (v0, IHl t v).
Defined.

Definition compact_sum_sigT_type {A} {P: A -> Type} (l: list (sigT P)): Type :=
  compact_sum (map (sigTT P) l).

Definition compact_sum_sigT_value: forall {A} {P: A -> Type} (l: list (sigT P)), compact_sum (map (sigTT P) l).
Proof.
  intros.
  destruct l as [| [t0 v0] l]; [exact tt |].
  revert t0 v0; destruct l as [| [t v] l]; intros.
  + exact v0.
  + exact (inl v0).
Defined.

Section CENV.

Context {cs: compspecs}.

Definition reptype_gen: type -> (sigT (fun x => x)) :=
  func_type (fun _ => (sigT (fun x => x)))
  (fun t =>
     if (type_is_by_value t)
     then existT (fun x => x) val Vundef
     else existT (fun x => x) unit tt)
  (fun t n a TV => match TV with existT T V => existT (fun x => x) (list T) nil end)
  (fun id a TVs => existT (fun x => x) (compact_prod_sigT_type (decay TVs)) (compact_prod_sigT_value (decay TVs)))
  (fun id a TVs => existT (fun x => x) (compact_sum_sigT_type (decay TVs)) (compact_sum_sigT_value (decay TVs))).

Definition reptype t: Type := match reptype_gen t with existT t _ => t end.
Definition default_val t: reptype t :=
  match reptype_gen t as tv
    return match tv with existT t _ => t end
  with existT t v => v end.

Lemma reptype_gen_ind: forall t,
  reptype_gen t =
  match t with
  | Tarray t0 _ _ => match reptype_gen t0 with existT T V => existT (fun x => x) (list T) nil end
  | Tstruct id _ => existT (fun x => x)
                     (compact_prod_sigT_type (map reptype_gen (map snd (co_members (get_co id)))))
                     (compact_prod_sigT_value (map reptype_gen (map snd (co_members (get_co id)))))
  | Tunion id _ => existT (fun x => x)
                     (compact_sum_sigT_type (map reptype_gen (map snd (co_members (get_co id)))))
                     (compact_sum_sigT_value (map reptype_gen (map snd (co_members (get_co id)))))
  | _ => if (type_is_by_value t)
         then existT (fun x => x) val Vundef
         else existT (fun x => x) unit tt
  end.
Proof.
  intros.
  unfold reptype_gen at 1.
  rewrite func_type_ind.
  destruct t; auto.
  + rewrite decay_spec.
    rewrite map_map.
    reflexivity.
  + rewrite decay_spec.
    rewrite map_map.
    reflexivity.
Qed.

Definition reptype_structlist (m: members) := compact_prod (map (fun it => reptype (snd it)) m).
Definition reptype_unionlist (m: members) := compact_sum (map (fun it => reptype (snd it)) m).

Notation REPTYPE t :=
  match t return Type with
  | Tvoid
  | Tfunction _ _ _ => unit
  | Tint _ _ _
  | Tlong _ _
  | Tfloat _ _
  | Tpointer _ _ => val
  | Tarray t0 _ _ => list (reptype t0)
  | Tstruct id _ => reptype_structlist (co_members (get_co id))
  | Tunion id _ => reptype_unionlist (co_members (get_co id))
  end.

Lemma reptype_ind: forall t,
  reptype t = REPTYPE t.
Proof.
  intros.
  unfold reptype.
  rewrite reptype_gen_ind at 1.
  destruct t as [| | | | | | | id ? | id ?]; auto.
  + destruct (reptype_gen t).
    reflexivity.
  + unfold compact_prod_sigT_type.
    forget (co_members (get_co id)) as m.
    rewrite map_map.
    rewrite map_map.
    reflexivity.
  + unfold compact_sum_sigT_type.
    forget (co_members (get_co id)) as m.
    rewrite map_map.
    rewrite map_map.
    reflexivity.
Qed.

Definition unfold_reptype {t} (v: reptype t): REPTYPE t :=
  @eq_rect Type (reptype t) (fun x: Type => x) v (REPTYPE t) (reptype_ind t).

Definition fold_reptype {t} (v: REPTYPE t): reptype t :=
  @eq_rect_r Type (REPTYPE t) (fun x: Type => x) v (reptype t) (reptype_ind t).

Lemma fold_unfold_reptype: forall t (v: reptype t),
  fold_reptype (unfold_reptype v) = v.
Proof.
  intros.
  unfold fold_reptype, unfold_reptype.
  apply JMeq_eq.
  match goal with
  | |- JMeq (@eq_rect_r ?A ?x ?F ?v ?y ?H) _ =>
    rewrite (eq_rect_r_JMeq A x y F v H)
  end.
  match goal with
  | |- JMeq (@eq_rect ?A ?x ?F ?v ?y ?H) _ =>
    rewrite (eq_rect_JMeq A x y F v H)
  end.
  reflexivity.
Defined.

Lemma unfold_fold_reptype: forall t (v: REPTYPE t),
  unfold_reptype (fold_reptype v) = v.
Proof.
  intros.
  unfold fold_reptype, unfold_reptype.
  apply JMeq_eq.
  match goal with
  | |- JMeq (@eq_rect ?A ?x ?F ?v ?y ?H) _ =>
    rewrite (eq_rect_JMeq A x y F v H)
  end.
  match goal with
  | |- JMeq (@eq_rect_r ?A ?x ?F ?v ?y ?H) _ =>
    rewrite (eq_rect_r_JMeq A x y F v H)
  end.
  reflexivity.
Defined.

Definition struct_default_val (m : members) := compact_prod_gen (fun it => default_val (snd it)) m.
Definition union_default_val (m : members) := compact_sum_gen (fun it => default_val (snd it)) m.

Lemma compact_prod_sigT_compact_prod_gen:
  forall {A B} {P: A -> Type} (genT: B -> A) (genV: forall b: B, P (genT b)) (gen: B -> sigT P) (l: list B),
    (forall b, gen b = existT P (genT b) (genV b)) ->
    JMeq (compact_prod_sigT_value (map gen l)) (compact_prod_gen genV l).
Proof.
  intros.
  assert (gen = fun b => existT P (genT b) (genV b)) by (extensionality; apply H).
  rewrite H0; clear H H0 gen.
  destruct l; [reflexivity |].
  revert b; induction l; intros.
  + reflexivity.
  + simpl map.
    change (compact_prod_gen genV (b :: a :: l)) with (genV b, compact_prod_gen genV (a :: l)).
    change (compact_prod_sigT_value
        (existT P (genT b) (genV b)
         :: existT P (genT a) (genV a)
            :: map (fun b0 : B => existT P (genT b0) (genV b0)) l)) with
      (genV b, compact_prod_sigT_value (existT P (genT a) (genV a) :: map (fun b0 : B => existT P (genT b0) (genV b0)) l)).
    apply JMeq_pair; [auto |].
    exact (IHl a).
Qed.

Lemma compact_sum_sigT_compact_sum_gen:
  forall {A B} {P: A -> Type} (genT: B -> A) (genV: forall b: B, P (genT b)) (gen: B -> sigT P) (l: list B),
    (forall b, gen b = existT P (genT b) (genV b)) ->
    JMeq (compact_sum_sigT_value (map gen l)) (compact_sum_gen genV l).
Proof.
  intros.
  assert (gen = fun b => existT P (genT b) (genV b)) by (extensionality; apply H).
  rewrite H0; clear H H0 gen.
  destruct l; [reflexivity |].
  destruct l.
  + reflexivity.
  + change (compact_sum_gen genV (b :: b0 :: l)) with
      (@inl (P (genT b)) (compact_sum (map (fun b1 : B => P (genT b1)) (b0 :: l))) (genV b)).
    change (compact_sum_sigT_value
        (map (fun b1 : B => existT P (genT b1) (genV b1)) (b :: b0 :: l))) with
  (@inl (P (genT b)) (compact_sum (map (fun tv => match tv with existT t _ => P t end) (map (fun b1 : B => @existT A P (genT b1) (genV b1)) (b0 :: l)))) (genV b)).
    change (compact_sum (map (fun tv => match tv with existT t _ => P t end) (map (fun b1 : B => @existT A P (genT b1) (genV b1)) (b :: b0 :: l)))) with
      (P (genT b) + compact_sum (map (fun tv => match tv with existT t _ => P t end) (map (fun b1 : B => @existT A P (genT b1) (genV b1)) (b0 :: l))))%type.
  match goal with
  | |- @JMeq _ (@inl _ ?A _) _ (@inl _ ?B _) =>
       replace A with B; [auto |]
  end.
  rewrite map_map; reflexivity.
Qed.

Lemma default_val_ind: forall t,
  default_val t =
  fold_reptype
  match t as t' return REPTYPE t'
  with
  | Tvoid
  | Tfunction _ _ _ => tt
  | Tint _ _ _
  | Tlong _ _
  | Tfloat _ _
  | Tpointer _ _ => Vundef
  | Tarray t0 _ _ => nil
  | Tstruct id _ => struct_default_val (co_members (get_co id))
  | Tunion id _ => union_default_val (co_members (get_co id))
  end.
Proof.
  intros.
  unfold fold_reptype.
  apply JMeq_eq.
  match goal with
  | |- JMeq _ (@eq_rect_r ?A ?x ?F ?v ?y ?H) =>
    rewrite (eq_rect_r_JMeq A x y F v H)
  end.
  unfold default_val.
  unfold reptype at 1.
  rewrite reptype_gen_ind.
  destruct t; auto.
  + unfold reptype.
    destruct (reptype_gen t).
    reflexivity.
  + unfold struct_default_val.
    rewrite map_map.
    apply (compact_prod_sigT_compact_prod_gen
      (fun it => reptype (snd it))
      (fun it => default_val (snd it))
      (fun it => reptype_gen(snd it))); intros.
    unfold reptype, default_val.
    destruct (reptype_gen (snd b)); reflexivity.
  + unfold union_default_val.
    rewrite map_map.
    apply (compact_sum_sigT_compact_sum_gen
      (fun it => reptype (snd it))
      (fun it => default_val (snd it))
      (fun it => reptype_gen(snd it))); intros.
    unfold reptype, default_val.
    destruct (reptype_gen (snd b)); reflexivity.
Qed.

Definition reptype': type -> Type :=
  func_type (fun _ => Type)
  (fun t =>
     if (type_is_by_value t)
     then match t with
          | Tint _ _ _ => int
          | Tlong _ _ => Int64.int
          | Tfloat _ _ => float
          | _ => val
          end
     else unit)
  (fun t n a T => list T)
  (fun id a T => compact_prod (decay T))
  (fun id a T => compact_sum (decay T)).

Notation REPTYPE' t :=
  match t return Type with
  | Tvoid
  | Tfunction _ _ _ => unit
  | Tint _ _ a => int
  | Tlong _ a => Int64.int
  | Tfloat _ a => float
  | Tpointer _ a => val
  | Tarray t0 _ _ => list (reptype' t0)
  | Tstruct id _ => compact_prod (map (fun it => reptype' (snd it)) (co_members (get_co id)))
  | Tunion id _ => compact_sum (map (fun it => reptype' (snd it)) (co_members (get_co id)))
  end.

Lemma reptype'_ind: forall t, 
  reptype' t = REPTYPE' t.
Proof.
  intros.
  unfold reptype'.
  rewrite func_type_ind with (t0 := t) at 1 by auto.
  destruct t; auto.
  + f_equal.
    rewrite decay_spec.
    reflexivity.
  + f_equal.
    rewrite decay_spec.
    reflexivity.
Qed.

Definition unfold_reptype' {t} (v: reptype' t): REPTYPE' t :=
  @eq_rect Type (reptype' t) (fun x: Type => x) v (REPTYPE' t) (reptype'_ind t).

Definition fold_reptype' {t} (v: REPTYPE' t): reptype' t :=
  @eq_rect_r Type (REPTYPE' t) (fun x: Type => x) v (reptype' t) (reptype'_ind t).

Lemma fold_unfold_reptype': forall t (v: reptype' t),
  fold_reptype' (unfold_reptype' v) = v.
Proof.
  intros.
  unfold fold_reptype', unfold_reptype'.
  apply JMeq_eq.
  match goal with
  | |- JMeq (@eq_rect_r ?A ?x ?F ?v ?y ?H) _ =>
    rewrite (eq_rect_r_JMeq A x y F v H)
  end.
  match goal with
  | |- JMeq (@eq_rect ?A ?x ?F ?v ?y ?H) _ =>
    rewrite (eq_rect_JMeq A x y F v H)
  end.
  reflexivity.
Defined.

Lemma unfold_fold_reptype': forall t (v: REPTYPE' t),
  unfold_reptype' (fold_reptype' v) = v.
Proof.
  intros.
  unfold fold_reptype', unfold_reptype'.
  apply JMeq_eq.
  match goal with
  | |- JMeq (@eq_rect ?A ?x ?F ?v ?y ?H) _ =>
    rewrite (eq_rect_JMeq A x y F v H)
  end.
  match goal with
  | |- JMeq (@eq_rect_r ?A ?x ?F ?v ?y ?H) _ =>
    rewrite (eq_rect_r_JMeq A x y F v H)
  end.
  reflexivity.
Defined.

Definition repinj_bv (t: type): reptype' t -> reptype t :=
  fun v =>
  fold_reptype
  (match t as t' return (REPTYPE' t' -> REPTYPE t': Type)
   with
   | Tvoid
   | Tfunction _ _ _ => @id unit
   | Tint _ _ a => Vint
   | Tlong _ a => Vlong
   | Tfloat _ a => Vfloat
   | Tpointer _ a => id
   | Tarray t0 n a => fun _ => nil
   | Tstruct id a => fun _ => struct_default_val _
   | Tunion id a => fun _ => union_default_val _
   end (unfold_reptype' v)).

Definition repinj_aux_s (id: ident) (a: attr) (F: ListType (map (fun it => reptype' (snd it) -> reptype (snd it)) (co_members (get_co id)))): reptype' (Tstruct id a) -> reptype (Tstruct id a) :=
  fun v => @fold_reptype (Tstruct id a) (compact_prod_map _ F (unfold_reptype' v)).

Definition repinj_aux_u (id: ident) (a: attr) (F: ListType (map (fun it => reptype' (snd it) -> reptype (snd it)) (co_members (get_co id)))): reptype' (Tunion id a) -> reptype (Tunion id a) :=
  fun v => @fold_reptype (Tunion id a) (compact_sum_map _ F (unfold_reptype' v)).

Definition repinj: forall t: type, reptype' t -> reptype t :=
  func_type (fun t => reptype' t -> reptype t)
  repinj_bv
  (fun t n a f v => @fold_reptype (Tarray t n a) (map f (unfold_reptype' v)))
  repinj_aux_s
  repinj_aux_u.

Lemma repinj_ind: forall t v,
  repinj t v =
  fold_reptype
  (match t as t' return REPTYPE' t' -> REPTYPE t' with
   | Tvoid
   | Tfunction _ _ _ => @id unit
   | Tint _ _ a => Vint
   | Tlong _ a => Vlong
   | Tfloat _ a => Vfloat
   | Tpointer _ a => id
   | Tarray t0 _ _ => map (repinj t0)
   | Tstruct id a => compact_prod_map _ (ListTypeGen (fun it => reptype' (snd it) -> reptype (snd it)) (fun it => repinj (snd it)) (co_members (get_co id)))
   | Tunion id a => compact_sum_map _ (ListTypeGen (fun it => reptype' (snd it) -> reptype (snd it)) (fun it => repinj (snd it)) (co_members (get_co id)))
   end (unfold_reptype' v)).
Proof.
  intros.
  unfold repinj.
  rewrite func_type_ind.
  destruct t; auto.
Qed.

Lemma int_add_repr_0_l: forall i, Int.add (Int.repr 0) i = i.
Proof. intros. apply Int.add_zero_l. Qed.
Lemma int_add_repr_0_r: forall i, Int.add i (Int.repr 0) = i.
Proof. intros. apply Int.add_zero. Qed.
Hint Rewrite int_add_repr_0_l int_add_repr_0_r : norm.

Definition repinject (t: type) : reptype t -> val :=
  match t as t0 return reptype t0 -> val with
  | Tint _ _ _ => fun v => v
  | Tlong _ _ => fun v => v
  | Tfloat _ _ => fun v => v
  | Tpointer _ _ => fun v => v
  | _ => fun _ => Vundef
 end.

Definition valinject (t: type) : val -> reptype t :=
  match t as t0 return val -> reptype t0 with
  | Tint _ _ _ => fun v => v
  | Tlong _ _ => fun v => v
  | Tfloat _ _ => fun v => v
  | Tpointer _ _ => fun v => v
  | t => fun _ => default_val t
 end.

Lemma valinject_JMeq: forall t v, type_is_by_value t = true -> JMeq (valinject t v) v.
Proof.
  intros.
  destruct t; simpl in *; try congruence; try tauto.
Qed.

Lemma repinject_unfold_reptype: forall t v,
  match t as t' return REPTYPE t' -> Prop with
  | Tint _ _ _
  | Tfloat _ _
  | Tlong _ _
  | Tpointer _ _ => fun vv => repinject t v = vv
  | _ => fun _ => True
  end (unfold_reptype v).
Proof.
  intros; destruct t; auto;
  unfold repinject;
  unfold unfold_reptype;
  rewrite <- eq_rect_eq; auto.
Qed.

End CENV.