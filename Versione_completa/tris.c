#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <Windows.h>
#include <ctype.h>
#include <time.h>

void minuscola(char *str) {
    for (int i = 0; str[i]; i++) {
        str[i] = (char)tolower((unsigned char)str[i]);
    }
}

void sistemaboard(char board[3][3]) {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            board[i][j] = ' ';
        }
    }
}

void mostraboard(char board[3][3]) {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            printf(" %c ", board[i][j]);
            if (j < 2) printf("|");
        }
        printf("\n");
        if (i < 2) printf("---+---+---\n");
    }
}

int vittoria(char board[3][3]) {
    for (int i = 0; i < 3; i++) {
        if (board[i][0] == board[i][1] && board[i][1] == board[i][2] && board[i][0] != ' ') {
            return 1;
        }
    }
    for (int j = 0; j < 3; j++) {
        if (board[0][j] == board[1][j] && board[1][j] == board[2][j] && board[0][j] != ' ') {
            return 1;
        }
    }
    if (board[0][0] == board[1][1] && board[1][1] == board[2][2] && board[0][0] != ' ') {
        return 1;
    }
    if (board[0][2] == board[1][1] && board[1][1] == board[2][0] && board[0][2] != ' ') {
        return 1;
    }
    return 0;
}

int pareggio(char board[3][3]) {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            if (board[i][j] == ' ') {
                return 0;
            }
        }
    }
    return 1;
}

int mossaSingolo(char board[3][3], int currentPlayer) {
    int riga, col;
    char simbolo = (currentPlayer == 1) ? 'X' : 'O';
    mostraboard(board);
    printf("Giocatore %d, inserisci la colonna e la riga (1-3) separati da uno spazio: ", currentPlayer);
    scanf("%d %d", &riga, &col);
    riga--;
    col--;

    if (riga >= 0 && riga < 3 && col >= 0 && col < 3 && board[riga][col] == ' ') {
        board[riga][col] = simbolo;
        Sleep(500);
        system("cls");
        return 1;
    } else {
        printf("Mossa non valida, riprova.\n");
        Sleep(1511);
        system("cls");
        return 0;
    }
}

int trova_mossa_vincente(char board[3][3], char simbolo) {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            if (board[i][j] == ' ') {
                board[i][j] = simbolo;
                if (vittoria(board)) {
                    board[i][j] = ' ';
                    return i * 3 + j;
                }
                board[i][j] = ' ';
            }
        }
    }
    return -1;
}

int mossaComputer(char board[3][3]) {
    int mossaValida = -1;
    mossaValida = trova_mossa_vincente(board, 'O');
    if (mossaValida != -1) {
        int riga = mossaValida / 3;
        int col = mossaValida % 3;
        board[riga][col] = 'O';
        Sleep(500);
        system("cls");
        return 1;
    }

    mossaValida = trova_mossa_vincente(board, 'X');
    if (mossaValida != -1) {
        int riga = mossaValida / 3;
        int col = mossaValida % 3;
        board[riga][col] = 'O';
        Sleep(500);
        system("cls");
        return 1;
    }

    srand((unsigned int)time(NULL));
    while (1) {
        int riga = rand() % 3;
        int col = rand() % 3;
        if (board[riga][col] == ' ') {
            board[riga][col] = 'O';
            Sleep(500);
            system("cls");
            return 1;
        }
    }
}

int mossaDoppio(char board[3][3], int currentPlayer) {
    int riga, col;
    char simbolo = (currentPlayer == 1) ? 'X' : 'O';
    mostraboard(board);
    printf("Giocatore %d, inserisci la colonna e la riga (1-3) separati da uno spazio: ", currentPlayer);
    scanf("%d %d", &riga, &col);
    riga--;
    col--;

    if (riga >= 0 && riga < 3 && col >= 0 && col < 3 && board[riga][col] == ' ') {
        board[riga][col] = simbolo;
        Sleep(500);
        system("cls");
        return 1;
    } else {
        printf("Mossa non valida, riprova.\n");
        Sleep(1511);
        system("cls");
        return 0;
    }
}

int main () {
    int start = 0;
    int modalità;
    char board[3][3];
    int currentPlayer = 1;
    int Vincita = 0;
    char controlli[100];
    do {
        printf("\n----IL TRIS----\n\n");
        Sleep(1000);
        printf("Benvenuti, per cominciare scegliere la modalita' di gioco:\n1) Contro di me;\n2) Contro un altro giocatore in locale;\nCosa scegliete (1/2)? ");
        scanf("%d", &modalità);
        if (modalità != 1 && modalità != 2) {
            printf("Inserito un valore non usabile, riprovare.\n");
            Sleep(1500);
            system("cls");
        }
    } while (modalità != 1 && modalità != 2);
    
    switch (modalità) {
        case 1:
            printf("Stai per giocare contro di me, sei pronto? ");
            do {
                scanf("%s", controlli);
                minuscola(controlli);

                if (strcmp("si", controlli) == 0) {
                    start = 1;
                    printf("Perfetto, cominciamo con i preparativi!\n");
                    Sleep(2000);
                    system("cls");
                } else {
                    printf("Va bene, aspettiamo qualche secondo.\n");
                    Sleep(4000);
                    printf("Ora ci sei? ");
                }
            } while (!start);

            printf("Il giocatore 1, che gioca per primo sarai tu e io saro' il giocatore 2 che gioca per secondo.\n");
            Sleep(2000);
            printf("Per poter mettere il tuo segno, devi inserire le coordinate delle caselle da 1 a 3.\n");
            Sleep(3000);
            printf("Con queste informazioni, cominciamo il gioco!\n");
            Sleep(1000);

            while (1) {
                sistemaboard(board);
                Vincita = 0;
                while (!Vincita && !pareggio(board)) {
                    currentPlayer = 1;
                    while (!mossaSingolo(board, currentPlayer)) {}
                    Vincita = vittoria(board);
                    if (!Vincita && !pareggio(board)) {
                        currentPlayer = 2;
                        mossaComputer(board);
                    }
                    Vincita = vittoria(board);
                }

                mostraboard(board);
                if (Vincita) {
                    printf("Il giocatore %d ha vinto!\n", currentPlayer);
                } else {
                    printf("Pareggio!\n");
                }
                Sleep(1500);
                printf("E' stato molto divertente, vuoi rifare la partita? ");
                scanf("%s", controlli);
                minuscola(controlli);
                if (strcmp("si", controlli) == 0) {
                    printf("Va bene, ripreparo tutto!\n");
                    Sleep(3000);
                    system("cls");
                } else {
                    printf("Grazie di avermi usato, alla prossima volta!\n");
                    Sleep(2400);
                    return 0;
                }
            }
        case 2:
            printf("Per giocare servono due persone, siete pronti? ");
            do {
                scanf("%s", controlli);
                minuscola(controlli);
                if (strcmp("si", controlli) == 0) {
                    start = 1;
                    printf("Perfetto, cominciamo con i preparativi!\n");
                    Sleep(2000);
                    system("cls");
                } else {
                    printf("Va bene, aspettiamo qualche secondo.\n");
                    Sleep(4000);
                    printf("Ora ci siete? ");
                }
            } while (!start);

            printf("Per cominciare, vi avviso che il giocatore che gioca per primo sara' l'1 e il secondo 2.\n");
            Sleep(2000);
            printf("Per poter mettere il proprio segno, si devono inserire le coordinate delle caselle da 1 a 3.\n");
            Sleep(3000);
            printf("Con queste informazioni, cominciamo il gioco!\n");
            Sleep(1000);

            while (1) {
                sistemaboard(board);
                Vincita = 0;
                while (!Vincita && !pareggio(board)) {
                    currentPlayer = 1;
                    while (!mossaDoppio(board, currentPlayer)) {}
                    Vincita = vittoria(board);
                    if (!Vincita) {
                        currentPlayer = 2;
                        while (!mossaDoppio(board, currentPlayer)) {}
                        Vincita = vittoria(board);
                    }
                }

                mostraboard(board);
                if (Vincita) {
                    printf("Il giocatore %d ha vinto!\n", currentPlayer);
                } else {
                    printf("Pareggio!\n");
                }
                Sleep(1500);
                printf("E' stato molto divertente vedervi giocare, volete rifarlo? ");
                scanf("%s", controlli);
                minuscola(controlli);
                if (strcmp("si", controlli) == 0) {
                    printf("Va bene, ripreparo tutto!\n");
                    Sleep(3000);
                    system("cls");
                } else {
                    printf("Grazie di avermi usato, alla prossima volta!\n");
                    Sleep(2400);
                    return 0;
                }
            }
    }
}
