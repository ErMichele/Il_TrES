#ifndef MICHELE_H
#define MICHELE_H

#include <stdio.h>
#include <ctype.h>
#include <time.h>
#include <stdarg.h>

// =====================================================================================
// Console Text Formatting Macros
// =====================================================================================

#define RESET "\033[0m"

// Text color codes
#define ROSSO "\033[31m"
#define VERDE "\033[32m"
#define GIALLO "\033[33m"
#define BLU "\033[34m"
#define CIANO "\033[36m"

// Background color codes
#define S_ROSSO "\033[41m"
#define S_VERDE "\033[42m"
#define S_GIALLO "\033[43m"
#define S_BLU "\033[44m"

// Text formatting codes 
#define GRASSETTO "\033[1m"
#define SOTTOLINEATO "\033[4m"
#define LAMPEGGIANTE "\033[5m"
#define INVERSIONE "\033[7m"

// =====================================================================================
// Struct Definitions
// =====================================================================================

/**
 * @brief Structure to represent physical quantities with value and uncertainty
 */
struct Grandezza_Fisica {
    double Valore;      /** Value of the physical quantity */
    double Incertezza;  /** Uncertainty associated with the physical quantity */
};

/**
 * @brief Structure to represent the solutions of a quadratic equation.
 */
struct Soluzioni_Quadratica {
    double Soluzione_Più; /** Positive solution (root) of the quadratic equation. */
    double Soluzione_Meno;  /** Negative solution (root) of the quadratic equation. */
};

// =====================================================================================
// Physical Costants
// =====================================================================================

#define Pi 3.14159265358979

// =====================================================================================
// Physical Quantities Conversion
// =====================================================================================

/**
 * @brief Converts degrees to radians.
 * 
 * @param n Angle in degrees.
 * @return double Angle in radians.
 */
double Gradi_Radiente (double n) {
    return (Pi * n) / 180;
}

/**
 * @brief Converts radians to degrees.
 * 
 * @param n Angle in radians.
 * @return double Angle in degrees.
 */
double Radiente_Gradi (double n) {
    return (180 * n) / Pi;
}

// =====================================================================================
// Advanced Mathematical Operations
// =====================================================================================

/**
 * @brief Computes the power of a number raised to a specified exponent.
 * 
 * @param numero The base number.
 * @param esponente The exponent to raise the base number to.
 * 
 * @return double The result of the base number raised to the exponent.
 */
double Potenza(double numero, int esponente) {
    double risultato = 1;
    if (esponente > 0) {
        for (int i = 1; i <= esponente; i++) {
            risultato *= numero;
        }
    } else if (esponente < 0) {
        for (int i = -1; i >= esponente; i--) {
            risultato *= numero;
        }
        risultato = 1 / risultato;
    }
    return risultato;
}

/**
 * @brief Computes the n-th root of a number using Newton's method.
 * 
 * @param numero The number whose n-th root is to be calculated.
 * @param indice The root index (e.g., 2 for square root, 3 for cube root, etc.).
 * @param tolleranza The acceptable tolerance for the result, indicating the desired level of precision.
 * 
 * @return double The calculated n-th root. Returns -1 in case of an error (e.g., even root of a negative number).
 */
double Radice(double numero, int indice, double tolleranza) {
    if (numero < 0 && indice % 2 == 0) {
        return -1;
        printf("Errore: il radicando %0.4lf è negativo e l'indice %d è un numero pari.", numero, indice);
    }
    double x = numero / indice; // Stima iniziale
    double differenza;
    do {
        double potenza = 1;
        for (int i = 1; i < indice; i++) {
            potenza *= x;
        }
        // Formula di Newton
        double nuovo_x = ((indice - 1) * x + numero / potenza) / indice;
        differenza = nuovo_x - x;
        if (differenza < 0) {
            differenza = -differenza;
        }
        x = nuovo_x;
    } while (differenza > tolleranza);
    return x;
}

/**
 * @brief Solves a quadratic equation of the form Ax^2 + Bx + C = 0.
 * 
 * @param A The quadratic coefficient (must be non-zero).
 * @param B The linear coefficient.
 * @param C The constant term.
 * @return struct Soluzioni A structure containing the two solutions.
 */
struct Soluzioni_Quadratica Formula_Quadratica (double A, double B, double C) {
    struct Soluzioni_Quadratica Risultati;
    double Discriminante = (B * B) - (4 * A * C);

    if (Discriminante > 0) {
        Risultati.Soluzione_Più = (-B + Radice(Discriminante, 2, 0.0001)) / (2 * A);
        Risultati.Soluzione_Meno = (-B - Radice(Discriminante, 2, 0.0001)) / (2 * A);
    } else if (Discriminante == 0) {
        Risultati.Soluzione_Più = Risultati.Soluzione_Meno = -B / (2 * A);
    } else {
        printf("Errore: discriminante negativo per numeri (A = %lf, B = %lf, C = %lf)!\n", A, B, C);
        Risultati.Soluzione_Più = Risultati.Soluzione_Meno = -1.0;
    }

    return Risultati;
}

/**
 * @brief Calculates the n-th Fibonacci number.
 * 
 * @param n The position of the Fibonacci number to calculate.
 * @return int The Fibonacci number at position n.
 */
int Fibonacci_Numero(int n) {
    if (n <= 0) {
        printf("Errore: n deve essere un numero positivo.\n");
        return -1;
    }
    if (n == 1) return 0;
    if (n == 2) return 1;

    int Valore_1 = 0, Valore_2 = 1, Risultato = 0;

    for (int i = 3; i <= n; i++) {
        Risultato = Valore_1 + Valore_2;
        Valore_1 = Valore_2;
        Valore_2 = Risultato;
    }

    return Risultato;
}

/**
 * @brief Computes the factorial of a non-negative integer.
 * 
 * @param n The integer whose factorial is to be calculated.
 * @return unsigned long long The factorial of the input integer.
 */
unsigned long long Fattoriale(int n) {
    if (n == 0 || n == 1) return 1;
    return n * Fattoriale(n - 1);
}

/**
 * @brief Computes the sine of an angle (in radians) using the Taylor series.
 * 
 * @param angolo Angle in radians.
 * @return double The calculated value of the sine.
 */
double Sen(double angolo) {
    double risultato = 0.0;
    for (int i = 0; i < 10; i++) { 
        int segno = (i % 2 == 0) ? 1 : -1;
        risultato += segno * Potenza(angolo, 2 * i + 1) / Fattoriale(2 * i + 1);
    }
    return risultato;
}

/**
 * @brief Computes the cosine of an angle (in radians) using the Taylor series.
 * 
 * @param angolo Angle in radians.
 * @return double The calculated value of the cosine.
 */
double Cos(double angolo) {
    double risultato = 0.0;
    for (int i = 0; i < 10; i++) {
        int segno = (i % 2 == 0) ? 1 : -1;
        risultato += segno * Potenza(angolo, 2 * i) / Fattoriale(2 * i);
    }
    return risultato;
}

/**
 * @brief Computes the tangent of an angle (in radians).
 * 
 * @param angolo Angle in radians.
 * @return double The calculated value of the tangent.
 */
double Tan(double angolo, char Unità) {
    double seno = Sen(angolo);
    double coseno = Cos(angolo);
    if (angolo <= 0) {
        printf("Errore: l'angolo deve essere un numero positivo.\n");
        return -1;
    }
    return seno / coseno;
}

// =====================================================================================
// Mathematical Operations on Physical Quantities
// =====================================================================================

/**
 * @brief Adds two physical quantities, considering their uncertainties.
 * 
 * @param Grandezza_1 First physical quantity.
 * @param Grandezza_2 Second physical quantity.
 * @return struct Grandezza_Fisica Resulting physical quantity from the sum.
 */
struct Grandezza_Fisica Somma_Fisica(struct Grandezza_Fisica Grandezza_1, struct Grandezza_Fisica Grandezza_2) {
    struct Grandezza_Fisica Grandezza_Risultato;
    Grandezza_Risultato.Valore = Grandezza_1.Valore + Grandezza_2.Valore;
    Grandezza_Risultato.Incertezza = Grandezza_1.Incertezza + Grandezza_2.Incertezza;
    return Grandezza_Risultato;
}

/**
 * @brief Subtracts two physical quantities, considering their uncertainties.
 * 
 * @param Grandezza_1 First physical quantity.
 * @param Grandezza_2 Second physical quantity.
 * @return struct Grandezza_Fisica Resulting physical quantity from the subtraction.
 */
struct Grandezza_Fisica Differenza_Fisica(struct Grandezza_Fisica Grandezza_1, struct Grandezza_Fisica Grandezza_2) {
    struct Grandezza_Fisica Grandezza_Risultato;
    Grandezza_Risultato.Valore = Grandezza_1.Valore - Grandezza_2.Valore;
    Grandezza_Risultato.Incertezza = Grandezza_1.Incertezza + Grandezza_2.Incertezza;
    return Grandezza_Risultato;
}

/**
 * @brief Multiplies two physical quantities, considering their uncertainties.
 * 
 * @param Grandezza_1 First physical quantity.
 * @param Grandezza_2 Second physical quantity.
 * @return struct Grandezza_Fisica Resulting physical quantity from the multiplication.
 */
struct Grandezza_Fisica Prodotto_Fisica(struct Grandezza_Fisica Grandezza_1, struct Grandezza_Fisica Grandezza_2) {
    struct Grandezza_Fisica Grandezza_Risultato;
    Grandezza_Risultato.Valore = Grandezza_1.Valore * Grandezza_2.Valore;
    Grandezza_Risultato.Incertezza = Grandezza_Risultato.Valore * ((Grandezza_1.Incertezza / Grandezza_1.Valore) + (Grandezza_2.Incertezza / Grandezza_2.Valore));
    return Grandezza_Risultato;
}

/**
 * @brief Divides two physical quantities, considering their uncertainties.
 * 
 * @param Grandezza_1 First physical quantity.
 * @param Grandezza_2 Second physical quantity.
 * @return struct Grandezza_Fisica Resulting physical quantity from the division.
 */
struct Grandezza_Fisica Divisione_Fisica(struct Grandezza_Fisica Grandezza_1, struct Grandezza_Fisica Grandezza_2) {
    struct Grandezza_Fisica Grandezza_Risultato;
    Grandezza_Risultato.Valore = Grandezza_1.Valore / Grandezza_2.Valore;
    Grandezza_Risultato.Incertezza = Grandezza_Risultato.Valore * ((Grandezza_1.Incertezza / Grandezza_1.Valore) + (Grandezza_2.Incertezza / Grandezza_2.Valore));
    return Grandezza_Risultato;
}

/**
 * @brief Raises a physical quantity to a specified power, taking uncertainties into account.
 * 
 * @param Grandezza The physical quantity to be raised.
 * @param Esponente The exponent to which the quantity is raised.
 * @return struct Grandezza_Fisica The resulting physical quantity after applying the power.
 */
struct Grandezza_Fisica Potenza_Fisica(struct Grandezza_Fisica Grandezza, int Esponente) {
    struct Grandezza_Fisica Grandezza_Risultato = Grandezza;
    if (Esponente == 0) {
        Grandezza_Risultato.Valore = 1;
        Grandezza_Risultato.Incertezza = 0;
    } else {
        Grandezza_Risultato.Valore = Potenza(Grandezza.Valore, Esponente);
        if (Esponente != 1) {
            Grandezza_Risultato.Incertezza = Grandezza_Risultato.Valore * (Esponente * (Grandezza.Incertezza / Grandezza.Valore));
        } else {
            Grandezza_Risultato.Incertezza = Grandezza.Incertezza;
        }
    }
    return Grandezza_Risultato;
}

/**
 * @brief Calculates the n-th root of a physical quantity, considering its uncertainty.
 * 
 * @param Grandezza The physical quantity whose n-th root is to be calculated.
 * @param Indice The root index (e.g., 2 for square root, 3 for cube root, etc.).
 * @return struct Grandezza_Fisica The resulting physical quantity after applying the n-th root operation.
 */
struct Grandezza_Fisica Radice_Fisica(struct Grandezza_Fisica Grandezza, int Indice) {
    struct Grandezza_Fisica Grandezza_Risultato;
    Grandezza_Risultato.Valore = Radice(Grandezza.Valore, Indice, 0.00001);
    Grandezza_Risultato.Incertezza = Grandezza.Incertezza * (1.0 / Indice) * (1.0 / Grandezza_Risultato.Valore);
    return Grandezza_Risultato;
}

// =====================================================================================
// Utility Functions
// =====================================================================================

/**
 * @brief Converts a string to lowercase for comparison purposes.
 * 
 * @param str String to convert
 */
void UniformaString(char *str) {
    if (str == NULL || str[0] == '\0') return;
    for (int i = 0; str[i]; i++) {
        str[i] = (char)tolower((unsigned char)str[i]);
    }
}

/**
 * @brief Logs a formatted message with a timestamp and log type to both the console and a file.
 * 
 * @param Tipo Log type/category (e.g., "INFO", "ERROR").
 * @param Messaggio Format string for the log message.
 * @param ... Arguments to format the message.
 */
void Logging(const char *Tipo, const char *Messaggio, ...) {
    char timestamp[20];
    time_t now = time(NULL);
    struct tm *local_time = localtime(&now);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", local_time);

    // Define the log file path
    const char *logFilePath = "./Logs/log.log";  // Uses relative path

    // Open the log file in append mode
    FILE *log_file = fopen(logFilePath, "a");
    if (!log_file) {
        // Try creating the directory if it doesn't exist
        #ifdef _WIN32
            _mkdir("./Logs");
        #else
            mkdir("./Logs", 0777);
        #endif

        // Attempt to open the file again
        log_file = fopen(logFilePath, "a");
        if (!log_file) {
            printf("Errore nell'apertura del file di log\n");
            return;
        }
    }

    va_list args;
    va_start(args, Messaggio);

    fprintf(stdout, "<%s> [%s] ", timestamp, Tipo);
    vfprintf(stdout, Messaggio, args);
    fprintf(stdout, "\n");

    fprintf(log_file, "<%s> [%s] ", timestamp, Tipo);
    vfprintf(log_file, Messaggio, args);
    fprintf(log_file, "\n");

    va_end(args);
    fclose(log_file);
}

#endif