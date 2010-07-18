# Gra w zgadywanie liczby
import random

iloscProb = 0

print('Cześć! Jak masz na imię?')
imie = input()

liczba = random.randint(1, 20)
print('Cześć ' + imie + '. Myślę o pewnej liczbie od 1 do 20.')

while iloscProb < 4:
    print('Zgaduj:')
    strzal = input()
    strzal = int(strzal)

    iloscProb = iloscProb + 1

    if strzal < liczba:
        print('Strzeliłeś zbyt małą liczbę') # na początku linii jest 8 spacji

    if strzal > liczba:
        print('Strzeliłeś zbyt dużą liczbę')

    if strzal == liczba:
        break

if strzal == liczba:
    iloscProb = str(iloscProb)
    print('Dobra robota, ' + imie + '! Zgadłeś moją liczbę po ' + iloscProb + ' próbach!')

if strzal != liczba:
    liczba = str(liczba)
    print('Nie. Liczba o której myślałem to ' + liczba)




