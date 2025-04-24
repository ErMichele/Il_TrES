#include "Michele.h"

__declspec(dllexport) int Pareggio(char Tavola[3][3]) {
    for (int Riga = 0; Riga < 3; Riga++) {
        for (int Colonna = 0; Colonna < 3; Colonna++) {
            if (Tavola[Riga][Colonna] == ' ') return -1;
        }
    }
    return 1;
}

__declspec(dllexport) int Vittoria(char Tavola[3][3]) {
    for (int Riga = 0; Riga < 3; Riga++) {
        if (Tavola[Riga][0] == Tavola[Riga][1] && Tavola[Riga][1] == Tavola[Riga][2] && Tavola[Riga][0] != ' ') return 1;
    }
    for (int Colonna = 0; Colonna < 3; Colonna++) {
        if (Tavola[0][Colonna] == Tavola[1][Colonna] && Tavola[1][Colonna] == Tavola[2][Colonna] && Tavola[0][Colonna] != ' ') return 1;
    }
    if (Tavola[0][0] == Tavola[1][1] && Tavola[1][1] == Tavola[2][2] && Tavola[0][0] != ' ') return 1;
    if (Tavola[0][2] == Tavola[1][1] && Tavola[1][1] == Tavola[2][0] && Tavola[0][2] != ' ') return 1;
    return -1;
}