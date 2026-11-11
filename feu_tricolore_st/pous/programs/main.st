PROGRAM main
  VAR
    etape : INT := 0;
    demande : BOOL := false;
    bouton_sim : BOOL := false;
    t_init : TON;
    t_vert : TON;
    t_orange : TON;
    t_pieton : TON;
    t_degage : TON;
    t_sim : TON;
  END_VAR
  VAR_INPUT
    bp_pieton : BOOL;
  END_VAR
  VAR_OUTPUT
    v_vert : BOOL;
    v_orange : BOOL;
    v_rouge : BOOL;
    p_vert : BOOL;
    p_rouge : BOOL;
  END_VAR


(* ===== 1. Simulation du bouton (impulsion toutes les 25 s) ===== *)
T_SIM(IN := NOT T_SIM.Q, PT := T#25s);
bouton_sim := T_SIM.Q;

(* ===== 2. Mémorisation de la demande ===== *)
IF BP_PIETON OR bouton_sim THEN demande := TRUE; END_IF;

(* ===== 3. Temporisations (appelées à chaque cycle) ===== *)
T_INIT(IN := (etape = 0), PT := T#2s);
T_VERT(IN := (etape = 1), PT := T#10s);
T_ORANGE(IN := (etape = 2), PT := T#3s);
T_PIETON(IN := (etape = 3), PT := T#8s);
T_DEGAGE(IN := (etape = 4), PT := T#2s);

(* ===== 4. Transitions du Grafcet ===== *)
CASE etape OF
  0: IF T_INIT.Q THEN etape := 1; END_IF;
  1: IF T_VERT.Q AND demande THEN etape := 2; END_IF;
  2: IF T_ORANGE.Q THEN
       etape := 3;
       demande := FALSE;
     END_IF;
  3: IF T_PIETON.Q THEN etape := 4; END_IF;
  4: IF T_DEGAGE.Q THEN etape := 1; END_IF;
END_CASE;

(* ===== 5. Sorties déduites de l'étape ===== *)
V_VERT   := (etape = 1);
V_ORANGE := (etape = 2);
V_ROUGE  := (etape = 0) OR (etape = 3) OR (etape = 4);
P_VERT   := (etape = 3);
P_ROUGE  := (etape = 0) OR (etape = 1) OR (etape = 2) OR (etape = 4);

END_PROGRAM