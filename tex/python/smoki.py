import random
import time

def pokazWstep():
    print('Jesteś w krainie pełnej smoków. Widzisz przed sobą')
    print('dwie jaskinie. W jednej z nich mieszka przyjazny smok')
    print('który podzieli się z tobą swoimi skarbami. W drugiej')
    print('smok jest chciwy i głodny, zje cię od razu.')
    print()

def wybierzJaskinie():
    jaskinia = ''
    while jaskinia != '1' and jaskinia != '2':
        print('Do ktorej jaskini wchodzisz? (1 lub 2)')
        jaskinia = input()

    return jaskinia

def sprawdzJaskinie(wybranaJaskinia):
    print('Wchodzisz do jaskini...')
    time.sleep(2)
    print('Jest ciemna i straszna...')
    time.sleep(2)
    print('Wielki smok wyskakuje tuż przed tobą! Otwiera szczęki i...')
    print()
    time.sleep(2)

    przyjaznaJaskinia = random.randint(1, 2)

    if wybranaJaskinia == str(przyjaznaJaskinia):
         print('Daje ci swoje skarby!')
    else:
         print('Pożera cię w całości!')

grajDalej = 'tak'
while grajDalej == 'tak' or grajDalej == 't':

    pokazWstep()

    numerJaskini = wybierzJaskinie()

    sprawdzJaskinie(numerJaskini)

    print('Czy chcesz zagrać jeszcze raz? (tak lub nie)')
    grajDalej = input()
