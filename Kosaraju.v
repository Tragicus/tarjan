From mathcomp Require Import all_ssreflect.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section Kosaraju.

Variable T : finType.
Implicit Types s : {set T}.
Implicit Types l : seq T.
Implicit Types A B C : pred T.
Implicit Types x y z : T.

Definition relto (V : finType) (a : pred V) (g : rel V) := 
   [rel x y | (y \in a) && g x y].

Lemma path_to a g z p : path (relto a g) z p = (path g z p) && (all a p).
Proof.
apply/(pathP z)/idP => [fgi|/andP[/pathP gi] /allP ga]; last first.
  by move=> i i_lt /=; rewrite gi ?andbT ?[_ \in _]ga // mem_nth.
rewrite (appP (pathP z) idP) //=; last by move=> i /fgi /= /andP[_ ->].
by apply/(all_nthP z) => i /fgi /andP [].
Qed.

Section Diconnect.

Variable r : rel T.
Local Notation "x -[]-> y" := 
  (connect r x y) (at level 10, format "x  -[]->  y") .

(* x is diconnected to y *)
Definition diconnect x y  :=  (connect r x y) && (connect r y x).

Local Notation "x =[]= y" := (diconnect x y) 
  (at level 10, format "x  =[]=  y").

Lemma diconnect_ref : reflexive diconnect.
Proof. by move=> x; apply/andP. Qed.

Lemma diconnect_sym : symmetric diconnect.
Proof. by move=> x y; apply/andP/andP=> [] []. Qed.

Lemma diconnect_trans : transitive diconnect.
Proof.
move=> x y z /andP[Cyx Cxy] /andP[Cxz Czx].
by rewrite /diconnect (connect_trans Cyx) ?(connect_trans Czx).
Qed.

End Diconnect.

Lemma eq_diconnect r1 r2 : r1 =2 r2 -> diconnect r1 =2 diconnect r2.
Proof.
by move=> r1Er2 x y; rewrite /diconnect !(eq_connect r1Er2).
Qed.

Section Relto.

Variable r : rel T.

Local Notation "x -[ s ]-> y" := 
  (connect (rel_of_simpl_rel (relto s r)) x y)
  (at level 10, format "x  -[ s ]->  y").

Local Notation "x -[]-> y" := 
  (connect r x y) (at level 10, format "x  -[]->  y") .

Local Notation "x =[]= y" := (diconnect r x y) 
  (at level 10, format "x  =[]=  y").

Lemma connect_relto_sub (a b : pred T) x y : 
  a \subset b -> x -[a]-> y -> x -[b]-> y.
Proof.
move=> /subsetP Hs.
apply/connect_sub => x1 y1 /= /andP[y1Ia x1Ry1].
by apply: connect1; rewrite /= Hs.
Qed.

Local Notation "x =[ a ]= y" := (diconnect (rel_of_simpl_rel (relto a r)) x y) 
  (at level 10, format "x  =[ a ]=  y").

Lemma diconnect_relto_sub (a b : pred T) x y : 
  a \subset b -> x =[a]= y -> x =[b]= y.
Proof. 
by move=> Hs /andP[Cxy Cyx]; rewrite /diconnect !(connect_relto_sub Hs).
Qed.

Lemma eq_diconnect_relto (a b : pred T) x y : 
  a =1 b -> x =[a]= y = x =[b]= y.
Proof.
move=> aEb; apply: eq_diconnect=> x1 y1.
by rewrite /= -!topredE /= aEb.
Qed.

Lemma diconnect_relto_predT : 
  diconnect (relto predT r) =2 diconnect r.
Proof. by move=> x y. Qed.
 
Lemma connect_reltoT :  (connect (relto predT r)) =2 (connect r).
Proof. by []. Qed.

Lemma connect_relto1 (a : pred T) x y : a y -> r x y -> x -[a]-> y.
Proof. by move=> ay Rxy; apply: connect1; rewrite /= [_ \in _]ay. Qed.

Lemma connect_reltoW a: 
  subrel (connect (relto a r)) (connect r).
Proof.
by apply: connect_sub => x y /andP[_ H]; apply: connect1.
Qed.

Lemma connect_relto_forced (a : pred T) x y :
 (forall z, z != x -> x -[]-> z ->  z -[]-> y -> a z) ->
  x -[]-> y ->  x -[a]-> y.
Proof.
move=> Hf /connectP[p {p}/shortenP[p Hp Up _ Hy]].
apply/connectP.
elim: p {-2 4}x Hy Up Hp (connect0 (relto a r) x) =>
   [z /=-> _ _ Hz| z p IH /= z1 Hy /and3P[H1 H2 H3] /andP[Rxy Pp] Hz1].
  by exists [::].
move: H1; rewrite inE negb_or => /andP[xDz H1].
have Az : a z.
  apply: Hf; first by rewrite eq_sym.
    apply: connect_trans (connect_reltoW Hz1) (connect1 Rxy).
    by apply/connectP; exists p.
have Raz : x -[a]-> z.
 by apply: connect_trans Hz1 (connect_relto1 Az Rxy).
have Uxp : uniq (x :: p) by rewrite /= H1.
have [p1 H1p1 H2p1] := IH _ Hy Uxp Pp Raz.
by exists (z :: p1); rewrite //= [_ \in _]Az Rxy.
Qed.

Lemma reltoI a b :
  relto (predI a b) r =2 relto a (relto b r).
Proof. by move=> x y; rewrite /= andbA. Qed.

Lemma connect_relto_C1r x y z :
  ~~ z -[]-> y ->  x -[]-> y -> x -[predC1 z]-> y.
Proof.
move=> Hzy Hxy.
apply: connect_relto_forced => //= z1 H1 H2 H3.
by apply/eqP=> H4; case/negP: Hzy; rewrite -H4.
Qed.

Lemma connect_relto_C1l x y z : 
  ~~ (x -[]-> z) ->  x -[]-> y -> x -[predC1 z]-> y.
Proof.
move=> Hzy Hxy.
apply: connect_relto_forced => //= z1 H1 H2 H3.
by apply/eqP=> H4; case/negP: Hzy; rewrite -H4.
Qed.

Lemma connect_relto_C1_id x y : x -[]-> y = x -[predC1 x]-> y.
Proof.
apply/idP/idP; last first.
  by apply: connect_sub => i j /= /andP[_ H1]; apply: connect1.
case/connectP => p /shortenP[p' Pxp' Uxp' Sxp' Lyxp'].
apply/connectP; exists p' => //=.
rewrite path_to Pxp'; apply/allP=> z zIp' /=.
have /= /andP[H _] := Uxp'.
by apply: contraNneq H => <-.
Qed.

(* Canonical element in a list : find the first element of l1
   that is equivalent to x walking in l2 *)
Definition can_relto x p := nth x p.2 (find (diconnect (relto p.1 r) x) p.2).

Local Notation "C[ x ]_ p" := (can_relto x p) 
  (at level 9, format "C[ x ]_ p").

Lemma eq_can_relto x a b l :  a =1 b -> C[x]_(a, l) = C[x]_(b, l).
Proof.
move=> aEb; rewrite /can_relto /=.
congr (nth _ _ _).
apply: eq_find => y.
by apply: eq_diconnect_relto.
Qed.

Lemma mem_can_relto x p : x \in p.2 -> C[x]_p \in p.2.
Proof.
move=> xIp1; rewrite /can_relto.
by case: (leqP (size p.2) (find (diconnect (relto p.1 r) x) p.2)) => H1;
  [rewrite nth_default | rewrite mem_nth].
Qed.

Lemma can_relto_cons x y a l : 
  C[x]_(a, y :: l) =  if x =[a]= y then y else C[x]_(a,l).
Proof.  by rewrite /can_relto /=; case: (boolP (diconnect _ _ _)) => Hr. Qed.

Lemma can_relto_cat x a l1 l2 : x \in l1 -> C[x]_(a, l1 ++ l2) = C[x]_(a, l1).
Proof.
move=> xIl1.
rewrite /can_relto find_cat; case: (boolP (has _ _)).
  by rewrite nth_cat has_find => ->.
by move/hasPn/(_ x xIl1); rewrite diconnect_ref.
Qed.

Lemma diconnect_can_relto x a l : x \in l -> C[x]_(a, l) =[a]= x.
Proof.
move=> xIl; rewrite diconnect_sym; apply: nth_find.
by apply/hasP; exists x => //; exact: diconnect_ref.
Qed.

(* x occurs before y in l *)
Definition before l x y  := index x l <= index y l.

Lemma before_filter_inv a x y l (l1 := [seq i <- l | a i]) :
  x \in l1 -> y \in l1 -> before l1 x y -> before l x y.
Proof.
rewrite {}/l1 /before; elim: l => //= z l IH.
case E : (a z) => /=.
  rewrite !inE ![_ == z]eq_sym.
  by case: eqP => //= Hx; case: eqP.
move=> xIl yIl; move: (xIl) (yIl).
rewrite !mem_filter.
case: eqP => [<-|_ _]; first by rewrite E.
case: eqP => [<-|_ _]; first by rewrite E.
by apply: IH.
Qed.

Lemma before_filter x y l a (l1 := [seq i <- l | a i]) :
  x \in l1 -> before l x y -> before l1 x y.
Proof.
rewrite {}/l1 /before; elim: l => //= z l IH.
case E : (a z) => /=.
  rewrite inE eq_sym.
  by case: eqP => //= Hx; case: eqP.
move=> xIl Hi; apply: IH => //.
by case: eqP xIl Hi => [<-| _]; [rewrite mem_filter E | case: eqP].
Qed.

Lemma leq_index_nth x l i : index (nth x l i) l  <= i.
Proof.
elim: l i => //= y l IH [|i /=]; first by rewrite eqxx.
by case: eqP => // _; apply: IH.
Qed.

Lemma index_find x l a :  has a l -> index (nth x l (find a l)) l = find a l.
Proof.
move=> Hal.
apply/eqP; rewrite eqn_leq leq_index_nth.
case: leqP => // /(before_find x).
by rewrite nth_index ?nth_find // mem_nth // -has_find.
Qed.

Lemma before_can_relto x y a l : 
  x \in l -> y \in l -> x =[a]= y -> before l C[x]_(a, l) y.
Proof.
move=> Hx Hy; rewrite diconnect_sym => Hr.
have F : has (diconnect (relto a r) x) l.
  by apply/hasP; exists y => //; rewrite diconnect_sym.
rewrite /before /can_relto index_find //.
case: leqP => // /(before_find x).
by rewrite nth_index // diconnect_sym Hr.
Qed.

Lemma before_can_reltoW x a b l : 
 x \in l -> b \subset a -> before l C[x]_(a, l) C[x]_(b, l).
Proof.
move=> xIl Hs.
have Hs1 : has (diconnect (relto a r) x) l.
  by apply/hasP; exists x => //; exact: diconnect_ref.
have Hs2 : has (diconnect (relto b r) x) l.
  by apply/hasP; exists x => //; exact: diconnect_ref.
rewrite /before /can_relto !index_find //.
apply: sub_find => z.
by apply: diconnect_relto_sub.
Qed.

End Relto.


Section ConnectRelto.

Variable r : rel T.

Local Notation "x -[ s ]-> y" := 
  (connect (rel_of_simpl_rel (relto s r)) x y)
  (at level 10, format "x  -[ s ]->  y").

Local Notation "x -[]-> y" := 
  (connect r x y) (at level 10, format "x  -[]->  y") .

Local Notation "x =[]= y" := (diconnect r x y) 
  (at level 10, format "x  =[]=  y").

Local Notation "x =[ a ]= y" := (diconnect (rel_of_simpl_rel (relto a r)) x y) 
  (at level 10, format "x  =[ a ]=  y").

Local Notation "C[ x ]_ p" := (can_relto r x p) 
  (at level 9, format "C[ x ]_ p").

(* well formed list : connected elements are inside and
                      canonical elements are on top *)
Definition wf_relto (p : (pred T) * seq T) := 
  p.2 \subset p.1 /\
 forall x y , 
   x \in p.2 -> x -[p.1]-> y -> y \in p.2 /\ before p.2 C[x]_p y.

Local Notation "W_[ s ] l" := (wf_relto (s, l)) 
  (at level 10, format "W_[ s ]  l").
Local Notation "W_[] l " := (wf_relto (predT,l)) 
  (at level 10, format "W_[]  l").

Lemma eq_wf_relto a b l :  a =1 b -> W_[a] l -> W_[b] l.
Proof.
move=> aEb [/= lSa Ca]; split => /= [|x y xIl xCy].
  apply: subset_trans lSa _.
  by apply/subsetP=> i; rewrite -!topredE /= aEb.
rewrite -(eq_can_relto _ _ _ aEb) //.
apply: Ca => //.
rewrite (eq_connect (_ : _ =2 relto b r)) // => x1 y1.
by rewrite /= -topredE /= aEb.
Qed.

Lemma wf_relto_nil a : W_[a] [::].
Proof. by split=> //; apply/subsetP => x. Qed.

(* Removing the equivalent elements of the top preserve well-formedness *)
Lemma wf_relto_inv x a l : 
  W_[a] (x :: l) -> W_[a] [seq y <- x :: l | ~~ x =[a]= y].
Proof.
move=> [ xlSa HR]; split => [|y z].
  rewrite /= diconnect_ref /=.
  apply/(subset_trans _ xlSa)/subsetP=> z /=.
  by rewrite !inE orbC mem_filter => /andP[_ ->].
rewrite !mem_filter => /andP[NxDy yIxl] yCz.
have ->: C[y]_(a, [seq i <- x :: l | ~~ x =[a]= i]) = C[y]_(a, x :: l).
  elim: (x :: l) => //= t l1 IH.
  case : (boolP (_ =[_]= _)) => Ext /=; last first.
    by rewrite /can_relto /=; case : (boolP (_ =[_]= _)).
  rewrite IH  /can_relto /=.
  case : (boolP (_ =[_]= _)) => Eyt //=.
  by case/negP: NxDy; apply: diconnect_trans Ext _; rewrite diconnect_sym.
have yIl : y \in l. 
  by move: yIxl NxDy; rewrite inE => /orP[/eqP->|//]; rewrite diconnect_ref.
have [zIxl Rz] := HR y z yIxl yCz.
have F : ~~ x =[a]= z.
  apply: contra NxDy => NxDz.
  have/HR[//|_] : y -[a]-> x.
    by apply: connect_trans yCz _; case/andP: NxDz.
  rewrite /before index_head /=.
  by case: eqP => //-> _; apply: diconnect_can_relto.
rewrite F; split => //.
apply: before_filter => //.
rewrite mem_filter mem_can_relto // ?andbT.
apply: contra NxDy => NxRc.
by apply: diconnect_trans NxRc (diconnect_can_relto _ _ _).
Qed.

(* Computing the connected elements for the reversed graph gives
   the equivalent class of the top element of an well_formed list *)
Lemma wf_relto_diconnect x y a l : 
  W_[a] (x :: l) -> x =[a]= y = (y \in x :: l) && y -[a]-> x.
Proof.
move=> [_ HR].
apply/idP/idP=> [/andP[Cxy Cyx]|/andP[yIxl Cyx]].
  case: (HR x y) => // [|->]; first by rewrite inE eqxx.
  by rewrite Cyx.
have F := diconnect_can_relto _ _ yIxl.
case: (HR y x) => // _.
by rewrite /before /= eqxx; case: eqP => //->.
Qed.

(* Computing well_formed list by accumulation *)
Lemma wf_relto_cat a l1 l2 (b : pred T := [predD a & [pred x in l1]]) : 
  W_[a] l1 -> W_[b] l2 -> W_[a] (l2 ++ l1).
Proof.
move=> [l1Sa Rl1] [l2Sb Rl2]; split => [|x y] /=.
  apply/subsetP => z; rewrite mem_cat => /orP[/(subsetP l2Sb)|/(subsetP l1Sa) //].
  by rewrite inE => /andP[].
have [xIl2 _ Hc|xNIl2] := boolP (x \in l2); last first.
  rewrite mem_cat (negPf xNIl2) /= => xIl1 Cxy.
  have /Rl1 - /(_ _ Cxy)[yIl1 Bxy] := xIl1.
  split; first by rewrite mem_cat yIl1 orbT.
  rewrite /before [index y _]index_cat.
  have [yIl2|yNil2] := boolP (y \in l2).
    have/subsetP/(_ y yIl2)/= := l2Sb.
    by rewrite !inE /= yIl1.
  rewrite index_cat; have [rIl2| rNIl2] := boolP (_ \in l2).
    by apply: leq_trans (index_size _ _) (leq_addr _ _).
  rewrite leq_add2l.
  move: rNIl2; rewrite /can_relto find_cat.
  have [HH|HH] := boolP (has _ _).
    by rewrite nth_cat -has_find HH mem_nth // -has_find.
  rewrite nth_cat ltnNge leq_addr /= => _.
  by rewrite addnC addnK.
have [/forallP F|] :=
     boolP [forall z, [&& z != x, x -[a]-> z & z -[a]-> y] ==> 
                   (z \notin l1)].
  have /(Rl2 _ _ xIl2) [yIl2 HB] : x -[b]-> y.
    have /eq_connect-> : 
      relto [predD a & [pred x in l1]] r =2
      relto [predC [pred x in l1]]  (relto a r).
      by move=> x1 y1; rewrite /= !inE !andbA.
    apply: connect_relto_forced => // z zDx xCz zCy.
    rewrite !inE /=.
    have /implyP->// := F z.
    by rewrite zDx xCz.
  split; first by rewrite mem_cat yIl2.
  rewrite /before [index y _]index_cat yIl2.
  apply: leq_trans HB.
  rewrite can_relto_cat // index_cat mem_can_relto //.
  apply: before_can_reltoW=> //; apply/subsetP=> i.
  by rewrite !inE => /andP[].
rewrite negb_forall => /existsP[z].
rewrite negb_imply -!andbA negbK => /and4P[zDx xCz zCy zIl1].
have [yIl1 HB] := Rl1 _ _ zIl1 zCy.
split; first by rewrite mem_cat yIl1 orbT.
rewrite /before [index y _]index_cat.
have [yIl2|_] := boolP (_ \in _).
  have/subsetP/(_ y yIl2)/= := l2Sb.
  by rewrite !inE yIl1.
rewrite index_cat.
have [_|/negP[]] := boolP (_ \in _).
  by apply: leq_trans (index_size _ _) (leq_addr _ _).
rewrite /can_relto; elim: (l2) xIl2 => //= a1 l IH.
rewrite inE => /orP[/eqP->|/IH]; first by rewrite diconnect_ref inE eqxx.
case: (_ =[_]= _) => //=; first by rewrite inE eqxx.
by rewrite inE orbC => ->.
Qed.

Lemma wf_relto_setU1_l x a l (b : pred T := [predD1 a & x]) :
   x \notin l ->  W_[a] l -> W_[b] l.
Proof.
move=> xNIl [lSa H]; split => /= [|t z tIl tCz].
  apply/subsetP=> i; rewrite !inE.
  by case: eqP => //= [-> /(negP xNIl)//|_ /(subsetP lSa)].
case: (H t z) => //= [|zIl Btz].
  apply: connect_sub tCz => x1 y1 /= /andP[].
  rewrite inE /= => /andP[_ y1Ia] x1Ry1.
  by apply: connect1; rewrite /= y1Ia.
split => //; suff->: C[t]_(b, l) = C[t]_(a, l) by [].
congr nth; apply: eq_in_find => y /= yIl.
have [xIa|xNIa] := boolP (x \in a); last first.
  apply: eq_diconnect_relto => x1.
  by rewrite /b /=; case: eqP=> // ->; rewrite [a _](negPf xNIa).
apply/idP/idP => /=. 
  apply/diconnect_relto_sub/subsetP=> u.
  by rewrite !inE => /andP[].
case/andP=> Cty Cyt.
have /eq_diconnect-> : relto b r =2 relto (predC1 x) (relto a r).
  by move=> x1 y1; rewrite /b /= !inE !andbA.
by apply/andP; split; apply: connect_relto_C1l => //; 
   apply: contra xNIl => /H[].
Qed.

(* Computing well_formed list by accumulation *)
Lemma wf_relto_cons_r x a l (b : pred T := [predD1 a & x]) :
 (forall y, y \in l -> x -[a]-> y) ->
 (forall y, r x y -> a y -> y != x -> y \in l) ->
  a x -> W_[b] l ->  W_[a] (x :: l).
Proof.
move=> AxC AyIl Ax [/= lSb Hl]; split => [|y z] /=.
  apply/subsetP=> y; rewrite inE => /orP[/eqP->//|/(subsetP lSb)].
  by rewrite inE=> /andP[].
have F t : t != x -> x -[b]-> t -> t \in l.
  move=> tDx /connectP[[_ [/eqP]|v p]] /=; first by rewrite (negPf tDx).
  rewrite -!andbA /= => /and4P[vDx vIa xRv Pbrvp tLvp].
  have: v \in l.
    by apply: AyIl => //; rewrite inE.
  by case/(Hl v t) => //; apply/connectP; exists p.
rewrite inE.
have Hr : relto b r =2 (relto (predC1 x) (relto a r)).
  by move=> x1 y1; rewrite /= !inE !andbA.
have [/eqP-> /= _ xCz|yDx /= yIl yCz] := boolP (y == x).
  split; last by rewrite /before /= can_relto_cons diconnect_ref eqxx.
  have [/eqP<-|zDx] := boolP (z == x); first by rewrite !inE eqxx.
  rewrite inE (F z) ?orbT // 1?eq_sym // (eq_connect Hr).
  by rewrite -connect_relto_C1_id.
have [yCz'|yNCz'] := boolP (y -[b]-> z).
  have [zIxs Byz] := Hl _ _ yIl yCz'.
  split; first by rewrite inE zIxs orbT.
  have [/eqP xEz|xDz] := boolP (x == z).
    rewrite can_relto_cons.
    suff->: y =[a]= x by rewrite /before /= eqxx.
    rewrite /diconnect {1}xEz yCz /=.
    by apply: AxC.
  rewrite can_relto_cons; case: (_ =[_]= _); first by rewrite /before /= eqxx.
  rewrite /before /= (negPf xDz); case: eqP => //= _.
  rewrite ltnS.
  apply: leq_trans Byz => /=.
  apply: before_can_reltoW => //; apply/subsetP=> i.
  by rewrite inE => /andP[].
have [yCx|yNCx] := boolP (y -[a]-> x); last first.
  case/negP: yNCz'.
  by rewrite (eq_connect Hr); apply: connect_relto_C1l.
have [xCz| xNCz] := boolP (x -[a]-> z); last first.
  case/negP: yNCz'.
  by rewrite (eq_connect Hr); apply: connect_relto_C1r.
split.
  rewrite inE.
  have [//|zDx/=] := boolP (z == x).
  apply: F => //.
  by rewrite (eq_connect Hr) -connect_relto_C1_id.
rewrite /before can_relto_cons.
suff->: y =[a]= x; first by rewrite /before /= eqxx.
rewrite /diconnect yCx /=.
by apply: AxC.
Qed.

End ConnectRelto.

Section Stack.

Variable r : rel T.

Local Notation "x -[ l ]-> y" := 
  (connect  (rel_of_simpl_rel (relto l r)) x y) 
  (at level 10, format "x  -[ l ]->  y").
Local Notation "x -[]-> y" := (connect r x y) 
  (at level 10, format "x  -[]->  y").
Local Notation "x =[ l ]= y" := (diconnect (relto l r) x y) 
  (at level 10, format "x  =[ l ]=  y").
Local Notation "x =[]= y" := (diconnect r x y) 
  (at level 10, format "x  =[]=  y").
Local Notation "W_[ l1 ] l2 " := (wf_relto r (l1, l2)) (at level 10).
Local Notation "W_[] l" := (wf_relto r (pred_of_simpl predT, l)) (at level 10).

Section Pdfs.

Variable g : T -> seq T.

Fixpoint rpdfs m (p : {set T} * seq T) x :=
  if x \notin p.1  then p else 
  if m is m1.+1 then 
     let p1 := foldl (rpdfs m1) (p.1 :\ x, p.2) (g x) in (p1.1, x :: p1.2)
  else p.

Definition pdfs := rpdfs #|T|.

End Pdfs.

Lemma pdfs_correct (p : {set T} * seq T) x :
  let (s, l) := p in 
  uniq l /\  {subset l <= ~: s} ->
  let p1 := pdfs (rgraph r) p x in
  let (s1, l1) := p1 in
  let ps : pred T := [pred x in s] in
  if x \notin s then p1 = p else
       [/\ #|s1| <= #|s| & uniq l1]
    /\
       exists l2 : seq T,
       [/\ x \in l2, s1 = s :\: [set y in l2], l1 = l2 ++ l, 
           W_[ps] l2 &
           forall y, y \in l2 -> x -[ps]-> y].
Proof.
rewrite /pdfs.
have: #|p.1| <= #|T| by apply/subset_leq_card/subsetP=> i.
elim: #|T| x p => /= [x [s l]|n IH x [s l]]/=.
  rewrite leqn0 => /eqP/cards0_eq-> [HUl HS].
  by rewrite inE.
have [xIs Hl [HUl HS]/=|xNIs Hl [HUl HS]//] := boolP (x \in s).
set p := (_, l); set F := rpdfs _ _; set L := rgraph _ _.
pose ps := pred_of_simpl [predD1 s & x].
have: 
     [/\ #|p.1| < #|s| & uniq p.2]
  /\
     exists l2,
      [/\  x \notin p.1, p.1 = (s :\ x) :\: [set z in l2], p.2 = l2 ++ l, W_[ps] l2 &
          forall y, y \in l2 -> x -[ps]-> y].
  split; [split => // | exists [::]; split => //=].
  - by rewrite /p /= [#|s|](cardsD1 x) xIs.
  - by rewrite !inE eqxx.
  - by rewrite setD0.
  by exact: wf_relto_nil.
have: forall y, r x y -> (y \notin p.1) || (y \in L).
  by move=> y; rewrite [_ \in rgraph _ _]rgraphK orbC => ->.
have: forall y, (y \in L) -> r x y.
  by move=> y; rewrite [_ \in rgraph _ _]rgraphK.
rewrite {}/p.
elim: L (_, _) => /=
    [[s1 l1] /= _ yIp [[sSs1 Ul1] [l2 [xIs1 s1E l1E Rwl2 xCy]]]|
    y l' IH1 [s1 l1] /= Rx yIp [[sSs1 Ul1] [l2 [xIs1 s1E l1E Rwl2 xCy]]]].
  split; [split=> // |exists (x :: l2); split] => // [||||||y].
  - rewrite subset_leqif_cards // s1E.
    by apply: subset_trans (subsetDl _ _) (subD1set _ _).
  - rewrite Ul1 andbT l1E mem_cat negb_or.
    have [/= Dl2 _] := Rwl2.
    have /subsetP/(_ x)/implyP/=  := Dl2.
    rewrite !inE /= eqxx implybF => ->.
    have  /implyP := HS x.
    by rewrite !inE xIs implybF.
  - by rewrite inE eqxx.
  - by apply/setP => z; rewrite s1E !inE negb_or andbC andbAC.
  - by rewrite l1E.
  - apply: wf_relto_cons_r => // [y yInl2|y /yIp].
    rewrite connect_relto_C1_id (eq_connect (_ : _ =2 (relto ps r))) ?xCy //.
      by move=> x1 y1; rewrite /= !inE andbA.
    rewrite orbF s1E 3!inE negb_and => /orP[]; first by rewrite negbK.
    by rewrite !inE negb_and => /orP[] /negPf->.
  rewrite inE => /orP[/eqP->|yIl2].
    by apply: connect0.
  apply: connect_sub (xCy _ yIl2) => i j /=.
  rewrite !inE -andbA => /and3P[H1 H2 H3].
  by apply: connect1; rewrite /= !inE H2.
have F1 : #|s1| <= n.
  by rewrite -ltnS (leq_trans _ Hl).
have F2 : {subset l1 <= ~: s1}.
  move=> i; rewrite l1E s1E !inE mem_cat => /orP[->//|/HS].
  by rewrite inE => /negPf->; rewrite !andbF.
have := IH y (s1, l1) F1 (conj Ul1 F2).
rewrite /F /=; case: rpdfs => s3 l3 /= Hv.
apply: IH1 => [z zIl|z Rxz /=|]; first by apply: Rx; rewrite inE zIl orbT.
  case: (boolP (y \in s1)) Hv =>
       [yIs1/= [[Ss1s3 Ul3] [l4 [yIl4 s3E l3E Rwl4 Cyz]]]
       |yNIs1/= [-> _]]; last first. 
    case: (yIp _ Rxz) => /orP[->//|].
    by rewrite inE => /orP[/eqP->|->]; [rewrite yNIs1|rewrite orbT].
  rewrite s3E !inE !negb_and.
  case/orP: (yIp _ Rxz) => [->//|]; first by rewrite orbT.
  rewrite inE => /orP[/eqP->|->]; last by rewrite orbT.
  by rewrite yIl4.
case: (boolP (y \in s1)) Hv =>
      [yIs1 [[Ss1s3 Ul3] [l4 [yIl4 s3E l3E Rwl4 Cyz]]]
      |yNIs1 [-> ->]]; last first.
  by split=> //; exists l2; split.
split; [split=> //= | exists (l4 ++ l2); split => //= [||||z]]. 
- by apply: leq_ltn_trans Ss1s3 _.
- by rewrite s3E s1E !inE eqxx !andbF.
- by apply/setP => i; rewrite s3E s1E !inE mem_cat negb_or -!andbA.
- by rewrite l3E l1E catA.
- apply: wf_relto_cat => //.
  apply: eq_wf_relto Rwl4 => i.
  by rewrite /= s1E !inE.
rewrite mem_cat => /orP[] zIl4; last by apply: xCy.
apply: connect_trans (_: y -[_]-> z); last first.
  apply: connect_sub (Cyz _ zIl4) => x1 y1.
  rewrite /= s1E !inE -!andbA => /and4P[H1 H2 H3 H4].
  by apply: connect1; rewrite /= !inE H2 H3.
apply: connect1.
rewrite /= !inE Rx ?andbT ?inE ?eqxx //.
by move: yIs1; rewrite s1E !inE=> /and3P[_ ->].
Qed.

Lemma pdfs_connect s x : 
  x \in s ->
  let (s1, l1) := pdfs (rgraph r) (s, [::]) x in
  [/\ uniq l1, s1 = s :\: [set x in l1], l1 \subset s & 
      forall y, y \in l1 = x -[[pred u in s]]-> y].
Proof.
move=> xIs.
set p := (_, _).
have UN : [/\ uniq p.2 & {subset p.2 <= ~: p.1}] by [].
case: pdfs (pdfs_correct (_, _) x UN) => s1 l1.
rewrite xIs => /=[[[_ Ul1] [l2 [xIl2 s1E l1E WH Cy]]]].
split => // [||y].
- by apply/setP=> i; rewrite s1E l1E !inE cats0.
- apply/subsetP=> z.
  rewrite l1E cats0.
  by have [/subsetP/(_ z)/=] := WH.
apply/idP/idP => [|H].
  by rewrite l1E cats0; exact: Cy.
rewrite l1E cats0.
by have [_ /(_ x y xIl2 H)[]] := WH.
Qed.

(* Building the stack of all nodes *)
Definition stack :=
  (foldl (pdfs (rgraph r)) (setT, [::]) (enum T)).2.

(* The stack is well-formed and contains all the nodes *)
Lemma stack_correct : W_[] stack /\ forall x, x \in stack.
Proof.
suff: [/\
        {subset (setT : {set T}, [::]).2  <= stack},
        W_[] stack &
         forall x : T, x \in (enum T) ->  x \in stack].
  case=> H1 H2 H3; split => // x.
  by rewrite H3 // mem_enum.
rewrite /stack; set F := foldl _; set p := (_, _).
have : W_[] p.2 by apply: wf_relto_nil.
have: p.1 = ~: [set x in p.2].
  by apply/setP=> i; rewrite /= !inE.
have: uniq p.2 by [].
elim: (enum T) p => /= [|y l IH [s1 l1] HUl1 /= Hi Rw].
  by split.
have HS : {subset l1 <= ~: s1}.
  by move=> i; rewrite Hi !inE negbK.
have :=  pdfs_correct (_, _) y (conj HUl1 HS).
have [yIs1|yNIs1] := boolP (y \in s1); last first.
  case: pdfs => s2 l2 [-> ->].
  have /= [Sl2 HR xI] := IH (s1,l1) HUl1 Hi Rw.
  split => // x.
  rewrite inE => /orP[/eqP->|xIl]; last by apply: xI.
  apply: Sl2.
  by move: yNIs1; rewrite Hi !inE negbK.
case: pdfs => s2 l2 /= [[Ss1s2 Ul2] [l3 [yIl3 s2E l2E RWl3 Cyz]]].
case: (IH (s2, l2)) => //= [|| Sl2F RwF FI]. 
- by apply/setP=> i; rewrite s2E Hi l2E !inE mem_cat negb_or.
- rewrite l2E; apply: (wf_relto_cat Rw).
  apply: eq_wf_relto RWl3 => i.
  by rewrite /= Hi !inE andbT.
split=> // [i iIl1|x]; first by rewrite Sl2F // l2E mem_cat iIl1 orbT.
rewrite inE => /orP[/eqP->|//]; last exact: FI.
by apply: Sl2F; rewrite l2E mem_cat yIl3.
Qed.

Lemma connect_relto_rev l a b x y : 
     {subset b <= a} -> 
     (forall z, (z \in b) = (z \in x :: l)) ->
     W_[a] (x :: l) ->
     ((y \in x :: l) && y -[a]-> x) = (connect (relto b [rel x y | r y x]) x y).

Proof.
move=> HS HD HW.
have [yIxl|yNIxl]/= := boolP (y \in _); last first.
  apply/sym_equal/idP/negP; apply: contra yNIxl.
  case/connectP=> p.
  have: x \in x :: l by rewrite inE eqxx.
  elim: p {1 3 4}x => /= [x1 x1Ixl _ [->]//|
                          z p /= IH x1 x1Ixl /andP[/andP[zIb zRx1] Pz] Lz].
  by apply: (@IH z); rewrite -?HD.
apply/idP/idP.
  case/connectP=> p.
  elim: p y yIxl => /=  [y yIxl _ -> //|
                         z p /= IH y yIxl /andP[/andP[zIa yRz] Pz] Lz].
  apply: connect_trans (_ : connect _ z y); last first.
    by apply: connect1; rewrite //= HD yIxl.
  apply: IH => //.
  have [_ /(_ y z yIxl)] := HW; case=> //.
  by  apply: connect1; rewrite /= ?zIa.
case/connectP=> p.
have xIxl : x \in x :: l by rewrite inE eqxx.
elim: p {1 3 4 5}x xIxl => /= [x1 x1Ixl1 _ -> //|
                               z p /= IH x1 x1Ixl /andP[/andP[zIb zRx1] Pz] Lz].
apply: connect_trans (_ : z -[a]-> x1); last first.
  apply: connect1 => //=.
  by rewrite zRx1 andbT HS // HD.
by apply: IH; rewrite -?HD.
Qed.

End Stack.

Variable r : rel T.

Definition kosaraju :=
  let f := pdfs (rgraph [rel x y | r y x]) in 
  (foldl  (fun (p : {set T} * seq (seq T)) x => if x \notin p.1 then p else 
                      let p1 := f (p.1, [::]) x in  (p1.1, p1.2 :: p.2))
          (setT, [::]) (stack r)).2.

Lemma kosaraju_correct :
    let l := flatten kosaraju in 
 [/\ uniq l, forall i, i \in l &
     forall c : seq T, c \in kosaraju -> 
        exists x, forall y, (y \in c) = (connect r x y && connect r y x)]. 
Proof.
rewrite /kosaraju.
set f := pdfs (rgraph [rel x y | r y x]).
set g := fun p x => if _ then _ else _.
set p := (_, _).
have: uniq (flatten p.2) by [].
have: forall c, c \in (flatten p.2) ++ (stack r).
  by move=>c; case: (stack_correct r) => _ /(_ c).
have: forall c, c \in p.2 -> 
                exists x, c =i (diconnect (relto predT r) x) by [].
have: ~: p.1 =i flatten p.2.
 by move=> i; rewrite !inE in_nil.
have: wf_relto r (predT : pred T, [seq i <- stack r | i \in p.1]).
  have->: [seq i <- stack r | i \in p.1] = stack r.
    by apply/all_filterP/allP=> y; rewrite inE.
  by case: (stack_correct r).
elim: stack p => [[s l]/= HR HI HE HFI HUF|].
  split=> // i.
  by have := HFI i; rewrite cats0.
move=> x l IH [s1 l1] HR HI HE HFI HUF.
rewrite /g /f /=.
have [xIs1|xNIs1] := boolP (x \in s1); last first.
  apply: IH => //= [|i]; first by move: HR; rewrite /= (negPf xNIs1).
  have:= HFI i; rewrite !mem_cat inE /=.
  by case: eqP => //->; rewrite -HI !inE xNIs1.
have := (@pdfs_connect ([rel x y | r y x]) s1 x xIs1).
case: pdfs => s2 l2 /= [Ul2 s2E Dl2 xCy].
move: HR; rewrite /= xIs1; set L := [seq _ <- _ | _] => HR.
have l2R : l2 =i (diconnect r x).
  move=> y.
  rewrite xCy -(@connect_relto_rev r L setT) //.
  - rewrite -wf_relto_diconnect //.
      rewrite -topredE /=.
      by apply: eq_diconnect => i j; rewrite /= !inE.
    by apply: eq_wf_relto HR => i; rewrite  !inE //= topredE inE.
  - move=> i; rewrite /= !inE mem_filter.
    have := HFI i; rewrite /= mem_cat -HI /= !inE.
    case: (_ =P _) => [->|] /=; first by rewrite xIs1.
    by case: (_ \in _).
 by apply: eq_wf_relto HR => i; rewrite // inE topredE inE.
apply: IH => [|i|i|i|] //=.
- suff->: [seq i <- l | i \in s2] =
          [seq i <- x :: L | ~~ diconnect r x i].
    by apply: wf_relto_inv.
  rewrite /= diconnect_ref /=.
  rewrite -filter_predI.
  apply: eq_filter => y /=.
  by rewrite s2E !inE l2R.
- by rewrite s2E !mem_cat !inE -HI negb_and negbK inE.
- by rewrite inE => /orP[/eqP->|//]; [exists x | apply: HE].
- have:= HFI i.
  rewrite /= !mem_cat !inE => /or3P[->|/eqP->|->].
  - by rewrite orbT.
  - by rewrite xCy connect0.
  by rewrite !orbT.
rewrite cat_uniq Ul2 HUF /= andbT.
apply/hasPn => i /=.
have/subsetP/(_ i)/= := Dl2.
by rewrite -HI /= !inE; do 2 case: (_ \in _).
Qed.

End Kosaraju.

Print rpdfs.
Print pdfs.
Print stack.
Print kosaraju.
Print dfs.

