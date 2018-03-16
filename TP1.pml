// Définition des variables globals pour faciliter la lecture du code
#define OUVERT 1
#define FERME 0
#define VERT 1
#define ROUGE 0
#define OUI 1
#define NON 0
#define ACTIF 1
#define DESACTIVE 0
#define ENTRE 1
#define SORTI 0

#define ETUDIANT 1
#define ENSEIGNANT 3
#define ADMINISTRATIF 5

#define VOLEUR 2
#define ANONYMOUS 4

#define OUVERTURE_SECOURS 9

#define CINQ_SECONDES 200000
#define TRENTE_SECONDES 1200000

chan STDIN;	/* Entrée standart */

// Autorisation de la porte : oui/non
chan autoriseCanal = [1] of { int };
// Voyant : vert/rouge
chan voyantCanal = [0] of {int};
// Porte :  ouvert/ferme
chan porteCanal = [1] of {int};
// Laser :  actif/desactive
chan laserCanal = [1] of {int, int};
// Alarme :  actif/desactive
chan alarmeCanal = [1] of {int};
// Incendie :  actif/desactive
chan incendieCanal = [1] of {int};

// Variables global
int nbPersonnesDansBatiment = 0;
int nbPersonne = 1;
int detectionLaser = 0;

// Définition de la stucture d'une info contenu dans une page
typedef info{
    int id;
    int state;
    int time;
};

// Définition du journal de bord
info journal[100];
int indice_journal = 0;

// Initialisation
init{
    run simulateur();
    run porte();
    run voyant();
    run affichage();
    run laser();
    run alarme();
    run incendie();
}

// Méthode qui permet de simuler une attente
inline wait(x){
    int a = 0;
    do
        ::a != x -> a = a + 1;
        ::a == x -> break;
    od
}

// Méthode qui affiche la structure journal défini plus haut
inline afficher_journal(){
    int i;
    printf("\n--------------JOURNAL--------------\n");
    for(i:0 .. indice_journal-1){
        printf("\nidentité: %d / état : %d / heure : %d\n",journal[i].id, journal[i].state, journal[i].time);
    }
}

// Agent qui réagit aux interactions de l'utilisateur avec la console
proctype simulateur(){
    int c;
    printf("\nAppuyer sur 1,3,5 pour un badge autorisé ou 2,4 pour un non-autorisé.\n");
    do::
        STDIN ? c
        if:: (c == 4) // Echap : quitter
            break;
        :: (c >= 49 && c <= 53) // 1 à 5 : personnes
            int id_badge = c - 48;
            run personne(id_badge);
        :: (c == 48) // 0 : incendie
            incendieCanal ! ACTIF;
        :: else // Autre entrée
            printf("\nMauvaise entrée (échap pour quitter).\n");
        fi
    od    
}

// Agent qui détecte un incendie, enclenche l'alarme et débloque toutes les portes
proctype incendie(){
    do::
        incendieCanal ? ACTIF;
        printf("\nUn incendie a été détecté !\n");
        alarmeCanal ! ACTIF;
        porteCanal ! OUVERTURE_SECOURS;
        afficher_journal();
    od
}

// Agent simule le comportement d'une personne qui désire entrer dans le bâtiment et sort au bout de 30 secondes
proctype personne(int id_badge){
    do::
        //Variable qui stocke le résultat d'autorisation de la porte
        int autorisation;

        printf("\nUne personne a passé son badge pour rentrer ! L'id du badge est : %d\n", id_badge);
        porteCanal ! id_badge;
        autoriseCanal ? autorisation;
        if::(autorisation == OUI) // Si le badge est valide
            printf("\nUne personne est entré dans le batîment ! L'id du badge est : %d\n", id_badge);
            // Enregistrement de l'entré d'une personne dans le journal
            journal[indice_journal].id = id_badge;
            journal[indice_journal].state = ENTRE;
            journal[indice_journal].time = indice_journal; // Optimise les performances le temps est simplement indice_journal
            indice_journal++;
            nbPersonnesDansBatiment++;
        ::else // Si le badge est invalide
            break;
        fi

        wait(TRENTE_SECONDES); // Une personne sort toujours du batiment au bout de trente secondes

        printf("\nUne personne a passé son badge pour sortir ! L'id du badge est : %d\n", id_badge);
        porteCanal ! id_badge;
        autoriseCanal ? autorisation;
        if::(autorisation == OUI) // Si le badge est valide
            printf("\nUne personne est sorti du batîment ! L'id du badge est : %d\n", id_badge);
            // Enregistrement de la sorti d'une personne dans le journal
            journal[indice_journal].id = id_badge;
            journal[indice_journal].state = SORTI;
            journal[indice_journal].time = indice_journal;
            indice_journal++;
            nbPersonnesDansBatiment--;
        ::else // Si le badge est invalide
            break;
        fi

        break;
    od
}

// Agent qui simule le comportement de la porte d'entré (commande le voyant et le laser)
proctype porte(){
    do::
        int id;
        porteCanal ? id;
        if::(id == ETUDIANT || id == ENSEIGNANT || id == ADMINISTRATIF) // Personnes autorisé
            voyantCanal ! VERT;
            autoriseCanal ! OUI;
            printf("\nLa porte est débloqué !\n");
            laserCanal ! ACTIF, 1; // ON PEUT CHANGER ICI LE NOMBRE DE PERSONNES RENTRÉ EN MEME TEMPS POUR SIMULER UNE FRAUDE.
            wait(CINQ_SECONDES);
            voyantCanal ! ROUGE;
            printf("\nLa porte est bloqué ! \n");
        ::(id == OUVERTURE_SECOURS) // Si un incendie est détecté par le capteur d'incendie
            printf("\nToutes les portes sont débloquées !\n");
        ::else // Personnes non-autorisé
            autoriseCanal ! NON; 
            printf("\nLa personne n'est pas autorisé\n");
        fi
    od
}

// Agent qui simule le comportement du laser et détecte du nombre de personnes simultané. Si > 1 déclenche l'alarme
proctype laser(){
    int nbPersonneDetecte;
    do::
        laserCanal ? ACTIF, nbPersonneDetecte;
        if::(nbPersonneDetecte > 1)
            printf("\nLe laser a détecté plusieurs passages !\n");
            alarmeCanal ! ACTIF;
        ::else
            printf("\nLe laser détecte un passage !\n");
        fi
    od
}

// Agent qui lance l'alarme
proctype alarme(){
    do::
        alarmeCanal ? ACTIF;
        printf("\nL'alarme a été déclenché ! BIP BIP BIP !\n");
    od
}

// Agent qui est contrôlé par la porte et contrôle l'éclairage et du voyant vert ou rouge
proctype voyant(){
    do::
        voyantCanal ? VERT;
        printf("\nLe voyant est vert ! \n");
        voyantCanal ? ROUGE;
        printf("\nLe voyant est rouge ! \n");
    od
}

// Agent lancé à l'initialisation du programme et permet d'afficher le nombre présent dans le batiment Maurienne toutes les 30 secondes.
proctype affichage(){
    do::
        wait(TRENTE_SECONDES);
        printf("\n\n\n")
        printf("BATIMENT MAURIENNE\n\n");
        printf("Nombre de personnes présents dans le batîment : %d \n\n\n", nbPersonnesDansBatiment);
    od
}


