#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <Windows.h>
#include <ctype.h>

// Funzioni per la gestione del gioco
int makeMove(char board[3][3], int currentPlayer);
int isBoardFull(char board[3][3]);
int checkWinner(char board[3][3]);
void printBoard(char board[3][3]);
void initializeBoard(char board[3][3]);
void minuscola(char* str);

int Titolo = 0;
char controlli[100]; // Stringa per memorizzare la risposta dell'utente

int main() {
    int Start = 0;
    char board[3][3];
    int currentPlayer = 1; // Giocatore 1 inizia
    int Vincinta = 0; // 0 = nessun vincitore, 1 = vincitore trovato

    // Messaggio di benvenuto
    if (!Titolo) {
        printf("\nBenvenuti al Tris!\n\n");
        Sleep(1000);
    }

    // Chiedi se sono pronti a giocare
    printf("Per giocare servono due persone, siete pronti? ");
    do {
        scanf("%s", controlli);
        minuscola(controlli);  // Converte l'input in minuscolo

        if (strcmp("si", controlli) == 0) {
            Start = 1;
            printf("Perfetto cominciamo con i preparativi!\n");
            Sleep(2000);
            system("cls");
        } else {
            printf("Va bene, aspettiamo qualche secondo.\n");
            Sleep(4000);
            printf("Ora ci siete? ");
        }
    } while (!Start);  // Continua finché non ricevono risposta "si"
    
    // Spiegazione del gioco
    printf("Per cominciare, vi avviso che il giocatore che gioca per primo sara' l'1 e il secondo 2.\n");
    Sleep(2000);
    printf("Per poter mettere il proprio segno, si devono inserire le coordinate delle caselle da 1 a 3.\n");
    Sleep(3000);
    printf("Con queste informazioni, cominciamo il gioco!\n");
    Sleep(1000);

    // Inizializza la griglia
    initializeBoard(board);

    // Ciclo principale del gioco
    while (!Vincinta && !isBoardFull(board)) {
        while (!makeMove(board, currentPlayer)) {
            // Continua a chiedere la mossa finché non è valida
        }

        Vincinta = checkWinner(board); // Controlla se c'è un vincitore
        if (!Vincinta) {
            currentPlayer = (currentPlayer == 1) ? 2 : 1; // Passa al giocatore successivo
        }
    }

    printBoard(board);
    
    if (Vincinta) {
        printf("Il giocatore %d ha vinto!\n", currentPlayer);
    } else {
        printf("Pareggio!\n");
    }
    Sleep (1500);
    printf ("E' stato molto divertente vedervi giocare, volete rifarlo? ");
    scanf ("%s", controlli);
    minuscola(controlli);
    if (strcmp ("si", controlli) == 0) {
        printf ("Va bene, ripreparo tutto!");
        Sleep (3000);
        Titolo = 1;
        system ("cls");
        main ();
    }
    else {
        printf("Grazie di avermi usaro, alla prossima!");
        Sleep (2500);
    }
    return 0;
}

// Funzione per fare una mossa
int makeMove(char board[3][3], int currentPlayer) {
    int row, col;
    char symbol = (currentPlayer == 1) ? 'X' : 'O'; // Determina il simbolo in base al giocatore
    printBoard(board);
    printf("Giocatore %d (%c), inserisci la colonna e la riga (1-3) separati da uno spazio: ", currentPlayer, symbol);
    scanf("%d %d", &row, &col);
    row--;
    col--;

    // Assicurati che la riga e la colonna siano nell'intervallo valido
    if (row >= 0 && row < 3 && col >= 0 && col < 3 && board[row][col] == ' ') {
        board[row][col] = symbol; // Inserisce la mossa
        Sleep(500);
        system("cls");
        return 1; // Mossa valida
    } else {
        printf("Mossa non valida, riprova.\n");
        Sleep(1500);
        system("cls");
        return 0; // Mossa non valida
    }
}


// Funzione per verificare se la griglia è piena
int isBoardFull(char board[3][3]) {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            if (board[i][j] == ' ') {
                return 0; // C'è almeno una cella vuota
            }
        }
    }
    return 1; // La griglia è piena
}

// Funzione per verificare se c'è un vincitore
int checkWinner(char board[3][3]) {
    // Controllo delle righe
    for (int i = 0; i < 3; i++) {
        if (board[i][0] == board[i][1] && board[i][1] == board[i][2] && board[i][0] != ' ')
            return 1; // Vincitore trovato
    }

    // Controllo delle colonne
    for (int j = 0; j < 3; j++) {
        if (board[0][j] == board[1][j] && board[1][j] == board[2][j] && board[0][j] != ' ')
            return 1; // Vincitore trovato
    }

    // Controllo della diagonale principale
    if (board[0][0] == board[1][1] && board[1][1] == board[2][2] && board[0][0] != ' ')
        return 1; // Vincitore trovato

    // Controllo della diagonale secondaria
    if (board[0][2] == board[1][1] && board[1][1] == board[2][0] && board[0][2] != ' ')
        return 1; // Vincitore trovato

    return 0; // Nessun vincitore
}

// Funzione per stampare la griglia
void printBoard(char board[3][3]) {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            printf(" %c ", board[i][j]);
            if (j < 2) printf("|"); // Aggiunge separatore verticale
        }
        printf("\n");
        if (i < 2) printf("---+---+---\n"); // Aggiunge separatore orizzontale
    }
}

// Funzione per inizializzare la griglia
void initializeBoard(char board[3][3]) {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            board[i][j] = ' '; // Imposta ogni cella come vuota
        }
    }
}

// Funzione per convertire una stringa in minuscolo
void minuscola(char* str) {
    for (int i = 0; str[i]; i++) {
        str[i] = tolower((unsigned char)str[i]);
    }
}
