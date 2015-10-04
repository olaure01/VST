Require Import Coqlib.
Require Import msl.Coqlib2.
Require Import List.
Import ListNotations.

Require Import floyd.sublist.

(* from verif_revarray.v *)

Definition flip_between {A} lo hi (contents: list A) :=
  firstn (Z.to_nat lo) (rev contents) 
  ++ firstn (Z.to_nat (hi-lo)) (skipn (Z.to_nat lo) contents)
  ++ skipn (Z.to_nat hi) (rev contents).

Lemma flip_fact_0: forall {A} size (contents: list A),
  Zlength contents = size ->
  contents = flip_between 0 (size - 0) contents.
Proof.
  intros.
  assert (length contents = Z.to_nat size).
    apply Nat2Z.inj. rewrite <- Zlength_correct, Z2Nat.id; auto.
    subst; rewrite Zlength_correct; omega.
  unfold flip_between.
  rewrite !Z.sub_0_r. change (Z.to_nat 0) with O; simpl. rewrite <- H0.
  rewrite skipn_short.
  rewrite <- app_nil_end.
  rewrite firstn_exact_length. auto.
  rewrite rev_length. omega.
Qed.

Lemma flip_fact_1: forall A size (contents: list A) j,
  Zlength contents = size ->
  0 <= j ->
  size - j - 1 <= j <= size - j ->
  flip_between j (size - j) contents = rev contents.
Proof.
  intros.
  assert (length contents = Z.to_nat size).
    apply Nat2Z.inj. rewrite <- Zlength_correct, Z2Nat.id; auto.
    subst; rewrite Zlength_correct; omega.
  unfold flip_between.
  symmetry.
  rewrite <- (firstn_skipn (Z.to_nat j)) at 1.
  f_equal.
  replace (Z.to_nat (size-j)) with (Z.to_nat j + Z.to_nat (size-j-j))%nat
    by (rewrite <- Z2Nat.inj_add by omega; f_equal; omega).
  rewrite <- skipn_skipn.
  rewrite <- (firstn_skipn (Z.to_nat (size-j-j)) (skipn (Z.to_nat j) (rev contents))) at 1.
  f_equal.
  rewrite firstn_skipn_rev.
Focus 2.
rewrite H2.
apply Nat2Z.inj_le.
rewrite Nat2Z.inj_add by omega.
rewrite !Z2Nat.id by omega.
omega.
  rewrite len_le_1_rev.
  f_equal. f_equal. f_equal.
  rewrite <- Z2Nat.inj_add by omega. rewrite H2.
  rewrite <- Z2Nat.inj_sub by omega. f_equal; omega.
  rewrite firstn_length, min_l. 
  change 1%nat with (Z.to_nat 1). apply Z2Nat.inj_le; omega.
  rewrite skipn_length.  rewrite H2.
  rewrite <- Z2Nat.inj_sub by omega. apply Z2Nat.inj_le; omega.
Qed.

Lemma Zlength_flip_between:
 forall A i j (al: list A),
 0 <= i  -> i<=j -> j <= Zlength al ->
 Zlength (flip_between i j al) = Zlength al.
Proof.
intros.
unfold flip_between.
rewrite !Zlength_app, !Zlength_firstn, !Zlength_skipn, !Zlength_rev.
forget (Zlength al) as n.
rewrite (Z.max_comm 0 i).
rewrite (Z.max_l i 0) by omega.
rewrite (Z.max_comm 0 j).
rewrite (Z.max_l j 0) by omega.
rewrite (Z.max_comm 0 (j-i)).
rewrite (Z.max_l (j-i) 0) by omega.
rewrite (Z.max_comm 0 (n-i)).
rewrite (Z.max_l (n-i) 0) by omega.
rewrite Z.max_r by omega.
rewrite (Z.min_l i n) by omega.
rewrite Z.min_l by omega.
omega.
Qed.

Lemma flip_fact_3:
 forall A (al: list A) (d: A) j size,
  size = Zlength al ->
  0 <= j < size - j - 1 ->
firstn (Z.to_nat j)
  (firstn (Z.to_nat (size - j - 1)) (flip_between j (size - j) al) ++
   firstn (Z.to_nat 1) (skipn (Z.to_nat j) (flip_between j (size - j) al)) ++
   skipn (Z.to_nat (size - j - 1 + 1)) (flip_between j (size - j) al)) ++
firstn (Z.to_nat 1)
  (skipn (Z.to_nat (size - j - 1)) al) ++
skipn (Z.to_nat (j + 1))
  (firstn (Z.to_nat (size - j - 1)) (flip_between j (size - j) al) ++
   firstn (Z.to_nat 1) (skipn (Z.to_nat j) (flip_between j (size - j) al)) ++
   skipn (Z.to_nat (size - j - 1 + 1)) (flip_between j (size - j) al)) =
flip_between (Z.succ j) (size - Z.succ j) al.
Proof.
intros.
assert (Zlength (rev al) = size) by (rewrite Zlength_rev; omega).
unfold flip_between.
rewrite Zfirstn_app1.
Focus 2. {
rewrite Zlength_firstn, Z.max_r by omega.
rewrite !Zlength_app.
rewrite Zlength_firstn, Z.max_r by omega.
rewrite Zlength_firstn, Z.max_r by omega.
rewrite !Zlength_skipn.
rewrite (Z.max_r 0 j) by omega.
rewrite (Z.max_r 0 (size-j)) by omega.
rewrite Z.max_r by omega.
rewrite Z.max_r by omega.
rewrite (Z.min_l j) by omega.
rewrite (Z.min_l (size-j-j)) by omega.
rewrite Z.min_l by omega.
omega.
} Unfocus.
rewrite Zfirstn_app2
 by (rewrite Zlength_firstn, Z.max_r by omega;
      rewrite Z.min_l by omega; omega).
rewrite Zfirstn_app1
 by (rewrite Zlength_firstn, Z.max_r by omega;
      rewrite Z.min_l by omega; omega).
rewrite Zfirstn_firstn by omega.
rewrite Zskipn_app1.
Focus 2. {
rewrite Zlength_firstn, Z.max_r by omega.
rewrite Zlength_rev. 
rewrite !Zlength_app.
rewrite Zlength_firstn, Z.max_r by omega.
rewrite Z.min_l by omega.
rewrite Zlength_firstn.
rewrite (Z.min_l j (Zlength al)) by omega.
rewrite Z.max_r by omega.
rewrite Zlength_app.
rewrite Zlength_firstn, Z.max_r by omega.
rewrite Zlength_skipn.
rewrite (Z.max_r 0 j)  by omega.
rewrite (Z.max_r 0 ) by omega.
rewrite (Z.min_l  (size-j-j)) by omega.
rewrite Zlength_skipn.
rewrite (Z.max_r 0 (size-j)) by omega.
rewrite Z.max_r by omega.
rewrite Z.min_l by omega.
omega.
} Unfocus.
rewrite Zskipn_app2
 by (rewrite Zlength_firstn, Z.max_r by omega;
       rewrite Z.min_l by omega; omega).
rewrite Zlength_firstn, Z.max_r by omega.
rewrite Z.min_l by omega.
rewrite Zfirstn_app1.
Focus 2. {
rewrite Zlength_firstn, Z.max_r by omega.
rewrite Zlength_skipn, (Z.max_r 0 j) by omega.
rewrite Z.max_r by omega.
rewrite Z.min_l by omega. omega.
} Unfocus.
rewrite Zfirstn_firstn by omega.
rewrite Zskipn_app2
 by (rewrite Zlength_firstn, Z.max_r by omega;
       rewrite Z.min_l by omega; omega).
rewrite Zskipn_app1.
Focus 2. {
rewrite Zlength_firstn, Z.max_r by omega.
rewrite Z.min_l by omega.
rewrite Zlength_firstn, Z.max_r by omega.
rewrite Zlength_skipn, (Z.max_r 0 j) by omega.
rewrite Z.max_r by omega.
rewrite Z.min_l by omega. omega.
} Unfocus.
rewrite Zfirstn_app1.
Focus 2. {
rewrite !Zlength_skipn, !Zlength_firstn.
rewrite (Z.max_r 0 j) by omega.
rewrite (Z.min_l j) by omega.
rewrite Zlength_skipn.
rewrite (Z.max_r 0 j) by omega.
rewrite (Z.max_r 0 (Zlength al - j)) by omega.
rewrite (Z.max_l 0 (j-j)) by omega.
rewrite (Z.max_r 0 (size-j-j)) by omega.
rewrite Z.min_l by omega.
rewrite Z.max_r by omega.
omega.
} Unfocus.
rewrite Zskipn_app2.
Focus 2. {
rewrite Zlength_firstn, Z.max_r by omega.
rewrite (Z.min_l j) by omega.
omega.
} Unfocus.
rewrite Zskipn_app2.
Focus 2. {
rewrite Zlength_firstn, Z.max_r by omega.
rewrite (Z.min_l j) by omega.
rewrite Zlength_firstn, Z.max_r by omega.
rewrite Zlength_skipn, (Z.max_r 0 j) by omega.
rewrite Z.max_r by omega.
rewrite Z.min_l by omega.
omega.
} Unfocus.
rewrite Zlength_firstn, Z.max_r by omega.
rewrite Zlength_firstn, Z.max_r by omega.
rewrite Zlength_skipn, (Z.max_r 0 j) by omega.
rewrite Z.max_r by omega.
rewrite Z.min_l by omega.
rewrite Z.min_l by omega.
rewrite Zskipn_skipn by omega.
rewrite !Zskipn_firstn by omega.
rewrite !Z.sub_diag.
rewrite Z.sub_0_r.
rewrite !Zskipn_skipn by omega.
rewrite Zfirstn_firstn by omega.
rewrite <- app_ass.
f_equal.
rewrite <- (firstn_skipn (Z.to_nat j) (rev al)) at 2.
rewrite Zfirstn_app2
  by (rewrite Zlength_firstn, Z.max_r by omega;
        rewrite Z.min_l by omega; omega).
rewrite Zlength_firstn, Z.max_r by omega;
rewrite Z.min_l by omega.
replace (Z.succ j - j) with 1 by omega.
f_equal.
rewrite app_nil_end.
rewrite app_nil_end at 1.
rewrite <- Znth_cons with (d0:=d) by omega.
rewrite <- Znth_cons with (d0:=d) by omega.
f_equal.
rewrite Znth_rev by omega.
f_equal. omega.
replace (size - j - 1 - j - (j + 1 - j))
  with (size- Z.succ j- Z.succ j) by omega.
replace (j+(j+1-j)) with (j+1) by omega.
f_equal.
rewrite Z.add_0_r.
rewrite <- (firstn_skipn (Z.to_nat 1) (skipn (Z.to_nat (size- Z.succ j)) (rev al))).
rewrite Zskipn_skipn by omega.
f_equal.
rewrite app_nil_end.
rewrite app_nil_end at 1.
rewrite <- Znth_cons with (d0:=d) by omega.
rewrite <- Znth_cons with (d0:=d) by omega.
f_equal.
rewrite Znth_rev by omega.
f_equal.
omega.
f_equal.
f_equal.
omega.
Qed.

Lemma flip_fact_2:
  forall {A} (al: list A) size j d,
 Zlength al = size ->
  j < size - j - 1 ->
   0 <= j ->
  Znth (size - j - 1) al d =
  Znth (size - j - 1) (flip_between j (size - j) al) d.
Proof.
intros.
unfold flip_between.
rewrite app_Znth2
 by (rewrite Zlength_firstn, Z.max_r by omega;
      rewrite Zlength_rev, Z.min_l by omega; omega).
rewrite Zlength_firstn, Z.max_r by omega;
rewrite Zlength_rev, Z.min_l by omega.
rewrite app_Znth1.
Focus 2. {
rewrite Zlength_firstn, Z.max_r by omega;
rewrite Zlength_skipn by omega.
rewrite (Z.max_r 0 j) by omega.
rewrite Z.max_r by omega.
rewrite Z.min_l by omega.
omega. } Unfocus.
rewrite Znth_firstn by omega.
rewrite Znth_skipn by omega.
f_equal; omega.
Qed.
