#define ouvert 99
#define ferme 99
#define vert 1
#define rouge 0
#define oui 1
#define non 0

chan STDIN;	/* no channel initialization */
chan autorise = [1] of { int };
//Voyant : vert/rouge
chan voyantCanal = [0] of {int};
//Porte :  débloqué/bloqué
chan porteCanal = [1] of {int};
int nbPersonnesDansBatiment = 0;
int nbPersonne = 1;

init{
    run simulateur();
    //run personnes();
    run porte();
    run voyant();
    run affichage();
}

inline wait(x)
{
    int a = 0;
    do
        ::a != x -> a = a + 1;
        ::a == x -> break;
    od;
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
            // Autre entrée.
            :: else -> printf("\nMauvaise entrée (échap pour quitter).\n");
            fi
    od    
}


proctype personne(int id_badge){
    do
        ::
        int autorisation;
        printf("\nUne personne a passé son badge pour rentrer ! L'id du badge est : %d\n", id_badge);
        porteCanal ! id_badge;
        autorise ? autorisation;
        if
            :: (autorisation == oui)
            wait(10000);
            printf("\nUne personne est entré dans le batîment ! L'id du badge est : %d\n", id_badge);
            nbPersonnesDansBatiment++;
        :: else -> break;
        fi

        wait(2000000);
        printf("\nUne personne a passé son badge pour sortir ! L'id du badge est : %d\n", id_badge);
        porteCanal ! id_badge;
        autorise ? autorisation;
        if
            :: (autorisation == oui)
            wait(10000);
            printf("\nUne personne est sorti du batîment ! L'id du badge est : %d\n", id_badge);
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
        if 
            :: (id == 1 || id == 3 || id == 5) ->
            voyantCanal ! vert;
            autorise! oui;
            printf("\nLa porte est débloqué !\n");
            wait(200000);
            voyantCanal ! rouge;
            printf("\nLa porte est bloqué ! \n");
        :: else ->
            autorise ! non;
            printf("\nLa personne n'est pas autorisé\n");
        fi
    od
}

proctype voyant(){
    do::
        voyantCanal ? vert;
        printf("\nLe voyant est vert ! \n");
        wait(1000);
        voyantCanal ? rouge;
        printf("\nLe voyant est rouge ! \n");
    od;
}

proctype affichage(){
    int nbtour = 1;
    do
        ::
        wait(1000000);
        printf("\n\n\n\n\n\n\n\n\n\n\n\n");
        printf("BATIMENT MAURIENNE (%d)\n\n", nbtour);
        printf("Nombre de personnes présents dans le batîment : %d \n\n\n", nbPersonnesDansBatiment);
        printf("\n\n\n\n\n\n");
        nbtour++;
    od;
}