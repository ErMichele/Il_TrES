#include "Michele.h"

__declspec(dllexport) int Vittoria(char Tavola[3][3]) {
    for (int Riga = 0; Riga < 3; Riga++) {
        if (Tavola[Riga][0] == Tavola[Riga][1] && Tavola[Riga][1] == Tavola[Riga][2] && Tavola[Riga][0] != ' ') return 10 + Riga;
    }
    for (int Colonna = 0; Colonna < 3; Colonna++) {
        if (Tavola[0][Colonna] == Tavola[1][Colonna] && Tavola[1][Colonna] == Tavola[2][Colonna] && Tavola[0][Colonna] != ' ') return 20 + Colonna;
    }
    if (Tavola[0][0] == Tavola[1][1] && Tavola[1][1] == Tavola[2][2] && Tavola[0][0] != ' ') return 31;

    if (Tavola[0][2] == Tavola[1][1] && Tavola[1][1] == Tavola[2][0] && Tavola[0][2] != ' ') return 32;

    return 0;
}

__declspec(dllexport) int Pareggio(char Tavola[3][3]) {
    if (Vittoria(Tavola) != 0) return 0;

    for (int Riga = 0; Riga < 3; Riga++) {
        for (int Colonna = 0; Colonna < 3; Colonna++) {
            if (Tavola[Riga][Colonna] == ' ')
                return 0;
        }
    }
    return -1;
}

__declspec(dllexport) void Log(const char *Tipo, const char *Messaggio) {
    Logging(Tipo, Messaggio);
}

int Trova_mossa_vincente(char board[3][3], char simbolo) {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            if (board[i][j] == ' ') {
                board[i][j] = simbolo;
                if (Vittoria(board)) {
                    board[i][j] = ' ';
                    return i * 3 + j;
                }
                board[i][j] = ' ';
            }
        }
    }
    return -1;
}

__declspec(dllexport) int MossaCPU(char board[3][3]) {
    int move;

    move = Trova_mossa_vincente(board, 'O');
    if (move != -1) return move;

    move = Trova_mossa_vincente(board, 'X');
    if (move != -1) return move;

    if (board[1][1] == ' ') return 1 * 3 + 1;

    srand((unsigned int)time(NULL));
    int available[9], count = 0;
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            if (board[i][j] == ' ')
                available[count++] = i * 3 + j;
        }
    }

    if (count > 0) {
        int r = rand() % count;
        return available[r];
    }

    return -1; // Non dovrebbe accadere
}
