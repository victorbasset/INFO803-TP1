#define ouvert 1
#define ferme 1
#define vert 1
#define rouge 0

chan badgeCanal = [0] of {int,int};

//Voyant : vert/rouge
chan voyantCanal = [0] of {int,int};

//Porte :  débloqué/bloqué
chan porteCanal = [1] of {int};

int nbPersonnesDansBatiment = 0;

int nbPersonne = 1;
int id = 0;

init{
    run personnes();
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

proctype personnes()
{
    int i = 0;

    do
        ::if
            ::(i < nbPersonne) ->
                run personne();
                wait(5000000);
                i++;
            ::else -> break;
        fi;
    od;
}


proctype personne(){
    id++
    int idpersonne = id;

    do
        ::
        printf("\nUne personne a passé son badge pour rentrer ! L'id de la personne est : %d\n", idpersonne);
        porteCanal ! ouvert;
        wait(10000);
        printf("\nUne personne est entré dans le batîment ! L'id de la personne est : %d\n", idpersonne);
        porteCanal ! ferme;
        nbPersonnesDansBatiment++;
        wait(4000000);
        printf("\nUne personne a passé son badge pour sortir ! L'id de la personne est : %d\n", idpersonne);
        porteCanal ! ouvert;
        wait(10000);
        printf("\nUne personne est sorti du batîment ! L'id de la personne est : %d\n", idpersonne);
        porteCanal ! ferme;
        nbPersonnesDansBatiment--;
        break;
    od;
}

proctype porte(){
    do
        ::
        porteCanal ? ouvert;
        printf("\nLa porte est débloqué !\n");
        voyantCanal ! vert;
        wait(500000);
        voyantCanal ! rouge;
        wait(1000000);
        porteCanal ? ferme;
        printf("\nLa porte est bloqué ! \n");
    od;
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
        wait(3000000);
        printf("\n\n\n\n\n\n\n\n\n\n\n\n");
        printf("BATIMENT MAURIENNE (%d)\n\n", nbtour);
        printf("Nombre de personnes présents dans le batîment : %d \n\n\n", nbPersonnesDansBatiment);
        printf("\n\n\n\n\n\n");
        nbtour++;
    od;
}