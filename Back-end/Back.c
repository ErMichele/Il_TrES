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
    if (Vittoria(Tavola) != 0) {
        return 0;
    }

    // Check if the board is full
    for (int Riga = 0; Riga < 3; Riga++) {
        for (int Colonna = 0; Colonna < 3; Colonna++) {
            if (Tavola[Riga][Colonna] == ' ') {
                return 0;
            }
        }
    }

    return -1;
}

__declspec(dllexport) void Log(const char *Tipo, const char *Messaggio) {
    Logging(Tipo, Messaggio);
}

int trova_mossa_vincente(char board[3][3], char simbolo) {
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

__declspec(dllexport) int mossaComputer(char board[3][3]) {
    int TentativoMossa = -1, Riga, Colonna;
    TentativoMossa = trova_mossa_vincente(board, 'O');
    if (TentativoMossa != -1) {
        Riga = TentativoMossa / 3;
        Colonna = TentativoMossa % 3;
        return Riga * 3 + Colonna;
    }

    TentativoMossa = trova_mossa_vincente(board, 'X');
    if (TentativoMossa != -1) {
        int riga = TentativoMossa / 3;
        int col = TentativoMossa % 3;
        return Riga * 3 + Colonna;
    }

    srand((unsigned int)time(NULL));
    while (1) {
        int Riga = rand() % 3;
        int Colonna = rand() % 3;
        if (board[Riga][Colonna] == ' ') return Riga * 3 + Colonna;
    }
}