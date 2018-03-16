#define ouvert 1
#define ferme 0
#define vert 1
#define rouge 0
#define oui 1
#define non 0
#define actif 1
#define desactive 0
#define personne_ok_1 1
#define personne_ok_2 3
#define personne_ok_3 5
#define personne_nok_1 2
#define personne_nok_2 4
#define ouverture_secours 0
#define entre 1
#define sorti 0

chan STDIN;	/* Entrée standart */

//CHANNELS
//Autorisation de la porte : oui/non
chan autoriseCanal = [1] of { int };
//Voyant : vert/rouge
chan voyantCanal = [0] of {int};
//Porte :  ouvert/ferme
chan porteCanal = [1] of {int};
//Laser :  actif/desactive
chan laserCanal = [1] of {int, int};
//Alarme :  actif/desactive
chan alarmeCanal = [1] of {int};
//Incendie :  actif/desactive
chan incendieCanal = [1] of {int};

//Variables global
int nbPersonnesDansBatiment = 0;
int nbPersonne = 1;
int detectionLaser = 0;

typedef info{
    int id;
    int state;
    int time;
};

info journal[100];
int indice_journal = 0;

init{
    run simulateur();
    run porte();
    run voyant();
    run affichage();
    run laser();
    run alarme();
    run incendie();
}

inline wait(x)
{
    int a = 0;
    do
        ::a != x -> a = a + 1;
        ::a == x -> break;
    od
}

proctype simulateur(){
    int c;
    printf("\nAppuyer sur 1,3,5 pour un badge autorisé ou 2,4 pour un non-autorisé.\n");
    do
        :: STDIN ? c ->
            if
            // Touche échap : quitter
            :: c == 4 -> break
            // Touches 1 à 5 pour les personnes
            :: (c >= 49 && c <= 53) ->
            int id_badge = c - 48;
            run personne(id_badge);
            :: (c == 48) ->
            incendieCanal ! actif;
            // Autre entrée.
            :: else -> printf("\nMauvaise entrée (échap pour quitter).\n");
            fi
    od    
}

inline afficher_journal(){
    int i = 0;
    printf("\n--------------JOURNAL--------------\n");
    for(i:0 .. indice_journal-1){
        printf("\nidentité: %d / état : %d / heure : %d\n",journal[i].id, journal[i].state, journal[i].time);
    }
}

proctype incendie(){
    do 
        ::
        incendieCanal ? actif;
        printf("\nUn incendie a été détecté !\n");
        alarmeCanal ! actif;
        porteCanal ! ouverture_secours;
        afficher_journal();
    od
}


proctype personne(int id_badge){
    do
        ::
        int autorisation;
        printf("\nUne personne a passé son badge pour rentrer ! L'id du badge est : %d\n", id_badge);
        porteCanal ! id_badge;
        autoriseCanal ? autorisation;
        if
            :: (autorisation == oui)
            wait(10000);
            printf("\nUne personne est entré dans le batîment ! L'id du badge est : %d\n", id_badge);
            journal[indice_journal].id = id_badge;
            journal[indice_journal].state = entre;
            journal[indice_journal].time = indice_journal;
            indice_journal++;
            nbPersonnesDansBatiment++;
        :: else -> break;
        fi

        wait(2000000);
        printf("\nUne personne a passé son badge pour sortir ! L'id du badge est : %d\n", id_badge);
        porteCanal ! id_badge;
        autoriseCanal ? autorisation;
        if
            :: (autorisation == oui)
            wait(10000);
            printf("\nUne personne est sorti du batîment ! L'id du badge est : %d\n", id_badge);
            journal[indice_journal].id = id_badge;
            journal[indice_journal].state = sorti;
            journal[indice_journal].time = indice_journal;
            indice_journal++;
            nbPersonnesDansBatiment--;
        :: else -> break;
        fi
        break;
    od
}

proctype porte(){
    do        
        ::
        int id;
        porteCanal ? id
        if::(id == personne_ok_1 || id == personne_ok_2 || id == personne_ok_3) ->
            voyantCanal ! vert;
            autoriseCanal ! oui;
            printf("\nLa porte est débloqué !\n");
            laserCanal ! actif, 1;
            wait(200000);
            voyantCanal ! rouge;
            printf("\nLa porte est bloqué ! \n");
        :: (id == 0) ->
            printf("\nToutes les portes sont débloquées !\n");
        :: else
            autoriseCanal ! non;
            printf("\nLa personne n'est pas autorisé\n");
        fi
    od
}



proctype laser(){
    int nbPersonneDetecte;
    do::
        laserCanal ? actif, nbPersonneDetecte;
        if::(nbPersonneDetecte > 1)
        printf("\nLe laser a détecté plusieurs passages !\n");
        alarmeCanal ! actif;
        ::else
        printf("\nLe laser détecte un passage !\n");
        fi
    od
}


proctype alarme(){
    do::
        alarmeCanal ? actif;
        printf("\nL'alarme a été déclenché ! BIP BIP BIP !\n");
    od
}

proctype voyant(){
    do::
        voyantCanal ? vert;
        printf("\nLe voyant est vert ! \n");
        wait(1000);
        voyantCanal ? rouge;
        printf("\nLe voyant est rouge ! \n");
    od
}

proctype affichage(){
    do
        ::
        wait(1000000);
        printf("\n\n\n")
        printf("BATIMENT MAURIENNE\n\n");
        printf("Nombre de personnes présents dans le batîment : %d \n\n\n", nbPersonnesDansBatiment);
    od
}


