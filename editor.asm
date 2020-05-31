
;Простейший текстовый редактор, позволяющий редактировать текстовые файлы ограниченного объема
;Режим компиляции по умолчанию
;Режим компоновки по умолчанию
;Файл по умолчанию ля редактирования NEW.TXT
;Тип исполняемого файла .exe
;Создание, открытие,сохраниние, редактирование текстовых документов 

.MODEL small 
.STACK 256 ; STACK
.DATA
    ROW DB 00
    COL DB 00
    Ltop DB 00
    LO DW 0
    ;------------------------------------------------------
    ;Ограничения перемещения курсора право, лево, низ, верх
    ;------------------------------------------------------
    Rlimit EQU 79   ;предел для курсора справа
    Llimit EQU 00   ;предел для курсора слева
    Dlimit EQU 21   ;предел для курсора снизу
    Tlimit EQU 02   ;предел для курсора сверху
    CHlimit EQU 79  ;предел количества символов в строке

    Str1 DB 8000 DUP(20H), 20H ; буфер для текста
    LIST LABEL BYTE            ; Метка для адреса имени файла
    MAX_L     DB     21        ; Максимальная длина имени файла
    LEN DB ?                   ; Длина имени файла  
    INDATA1 DB 23 DUP(' ')     ; Буфер для имени файла
    filenum DB 0               ; Число открытых файлов
    FILHAND DW ?               ; Дескриптор файла
    ERROR DB '******ERROR******','$'; Сообщение об ошибке
    NEW DB 'NEW.TXT',0              ; Имя файла по умолчанию
.CODE
    MAIN PROC 
        MOV AX, @DATA           
        MOV DS, AX             ; Инициализация ds
        MOV ES, AX             ; Инициализация es
        CALL MENUBAR           ; Показать меню
        CALL First             ; Создать новый файл
        MOV COL, 0             ; Задать положение курсора в столбце
        MOV ROW, 2             ; Задать положение курсора в строке
GetKey:
        CALL SETLO              ; Перемнстить курсор (столбец, строка)
        CALL KEYIN              ; Проверка нажатия клавиш
        JMP GetKey              ; в цикл

Fail:
        ; Выход из программы
        MOV AX, 4C00H
        INT 21H
    MAIN    ENDP
.386

    ;---------------------------------------
    ; Создать новый файл
    ;---------------------------------------
    First    PROC    NEAR
        MOV AH, 3CH
        MOV CX, 0              ; Создается обычный файл
        LEA DX, NEW            ; Имя файла
        INT 21H                
        JC CREATEFAIL          ; Проверка на ошибку при создании файла
        MOV FILHAND, AX        ; Сохранить дескриптор файла
        JMP CREATESUCCESS      ; Успешно создан
CREATEFAIL:
        LEA DX, ERROR          ; Вывод сообщения 
        MOV AH, 09H            ; об ошибке
        INT 21H        
CREATESUCCESS:
        RET
    First    ENDP
    ;---------------------------------------
    ; Создать новый файл или открыть предыдущий
    ;---------------------------------------
    File    PROC    NEAR
        PUSH CX                   ; Сохряняем CX
        PUSH AX                   ; Сохряняем AX
        CMP filenum, 02           ; Максимально возможное число открытых файлов 
        JAE tooMany               ; Если больше
        CLC                       ; Очистка флага CF
        MOV ROW, 24               ; Строка 24
        MOV COL, 9                ; Столбец 9
        CALL SETLO                ; Переместить курсор для ввода файлового имени
        CALL FILENAME             ; Получить имя файла
        POP AX                    ; Восстанавливаем AX
        MOV AL, 02
        MOV CX, 00                ; Обычный файл
        LEA DX, INDATA1           ; Сохранить имя файла
        INT 21H
        JC FILEEROR               ; Ошибка 
        MOV FILHAND, AX           ; Сохранить дескриптор
        JMP FILEOK                ; Успешно
FILEEROR:        
        MOV ROW, 24               ; Строка 24
        MOV COL, 9                ; Столбец 9
        CALL SETLO                ; Курсор вниз для вывода сообщения об ошибке
        LEA DX, ERROR             ; Для сообщения ошибки
        MOV AH, 09H
        INT 21H                
FILEOK:
        ;---------------------------------------    
        ; Вернуть курсор в начало
        ;---------------------------------------    
        MOV ROW, 00               ; Строка 0
        MOV COL, 00               ; Столбец 0
        CALL SETLO                ; Курсор в начало
        POP CX                    
        RET
tooMany:
        POP AX
        JMP FILEEROR              ; Файл создан/открыт с ошибкой 
    File ENDP

    ;---------------------------------------
    ;Сохранить файл 
    ;---------------------------------------
    WRITE    PROC    NEAR
        CLC
        MOV AH, 40H
        MOV BX, FILHAND        ; Получить дескриптор файла
        MOV CX, 8000           ; Количество байт для записи
        LEA DX, Str1           ; Данные для записи
        INT 21H                ; Записать данные
        JNC SAVEOK             ; Успешное сохраниние
        LEA DX, ERROR          ; Вывод ошибки если не удалось сохранить
        MOV AH, 09H
        INT 21H
SAVEOK: 
        MOV ROW, 00             ; Строка 0
        MOV COL, 00             ; Столбец 0

        CALL RETURNFILE         ; Указатель в начало файла

        PUSH AX                 ; Cохряняем AX
        PUSH CX                 ; Cохряняем CX
        MOV ROW, 24             ; Курсор вниз 
        MOV COL, 9          
        CALL SETLO              ; Переместить курсор
        ; Очистить введенное имя файла
        MOV CX,25               ; Сколько удалить         
        MOV AL,20H
EMPT:  CALL aChar               ; Удаление (затираем пробелами)
        LOOP EMPT
        MOV ROW,24              ; Строка 24 
        MOV COL,9               ; Столбец 9
        CALL SETLO              ; Вернуть указатель

        CALL CLEANBUF           ; Очистить буфер имени файла
        POP CX                  ; Восстановить CX
        POP AX                  ; Восстановить AX

        CALL CLEANSCREEN        ;Очистить экран
        CALL CLEANBUFF          ;Очистить основной буфер для текста


        MOV ROW,1               
        MOV COL,0
        CALL SETLO              ; Перемещаем курсор
ret
    WRITE ENDP
    ;---------------------------------------
    ;Открыть файл
    ;---------------------------------------
    READ PROC NEAR
        MOV AH, 3FH
        MOV BX, FILHAND        ; Дескриптор файла 
        MOV CX, 8000           ; Количество байт для чтения
        LEA DX, Str1           ; Считываемые данные 
        INT 21H               
        JC NEWFAIL             ; Вывод ошибки если не удалась
        JMP NEWOK
NEWFAIL:
        LEA DX, ERROR          ; Вывод сообщения об ошибке
        MOV AH, 09H            ; Вывод
        INT 21H        
NEWOK:  
    ;---------------------------------------  
    ; Вернуть курсор в начало
    ;---------------------------------------       
        MOV ROW, 00            ; Строка 0
        MOV COL, 00            ; Столбец 0
        CALL SETLO             ; Курсор в начало
        CALL RETURNFILE        ; Указатель в начало файла
RET
    READ ENDP
    ;---------------------------------------
    ; Закрыть файл
    ;---------------------------------------
    CLOSE PROC NEAR
        MOV BX, FILHAND         ; Дескрипрор файла 
        MOV AH, 3EH             ; Закрыть файл
        INT 21H                 
        RET
    CLOSE ENDP
    ;---------------------------------------
    ; Получить имя файла
    ;---------------------------------------
    FILENAME PROC NEAR
        PUSH AX                 ; Сохранить AX
        PUSH CX                 ; Сохранить CX
        MOV ROW, 24             ; Строка 24
        MOV COL, 9              ; Столбец  9
        CALL SETLO              ;Переместить курсор

        ; очистить введенное имя

        MOV  CX,25              ; Количество символов для удаления
        MOV AL,20H              ; Пробел
EMPTY:  CALL aChar                
        LOOP EMPTY              ; Удалить имя файла (затираем пробелами)
        MOV ROW,24              ; Строка
        MOV COL,9               ; Столбец 
        CALL SETLO              ; Курсор назад

        CALL CLEANBUF           ; Очистить буфер имени файла
        
        ; ввод имени файла

        MOV AH, 0AH             ; Функция считывания
        LEA DX, LIST            ; Адрес буфера для имени
        INT 21h                 ; Считываем имя файла
        MOVZX BX, LEN           ; Расширить значение и поместить в BX
        MOV INDATA1[BX], 00H    ; Поместить ноль 

        POP CX                  ; Восстановить CX
        POP AX                  ; Восстановить AX
        RET
    FILENAME ENDP

    ;---------------------------------------
    ; Отображение меню
    ;---------------------------------------
    MENUBAR    PROC    NEAR
        MOV  AX,0600H      ;AH 06 (прокрутка)
                           ;AL 00 (весь экран)
            MOV BH,07     ;Нормальный атрибут (черно/белый)
            MOV CX,0000   ;Верхняя левая позиция
            MOV DX,184FH  ;Нижняя правая позиция
            INT 10H 
        CALL SETLO        
        ;Вывод меню 
        MOV AH, 02H
        MOV DL, 'C'   
        INT 21H
        MOV DL, 'r'
        INT 21H
        MOV DL, 'e'
        INT 21H
        MOV DL, 'a'
        INT 21H
        MOV DL, 't'
        INT 21H
        MOV DL, 'e'
        INT 21H
        MOV DL, ' '
        INT 21H
        MOV DL, 'O'
        INT 21H
        MOV DL, 'p'
        INT 21H
        MOV DL, 'e'
        INT 21H
        MOV DL, 'n'
        INT 21H
        MOV DL, ' '
        INT 21H
        MOV DL, 'S'
        INT 21H
        MOV DL, 'a'
        INT 21H
        MOV DL, 'v'
        INT 21H
        MOV DL, 'e'
        INT 21H
        MOV DL, ' '
        INT 21H
        
        INT 21H
        MOV DL, 'E'
        INT 21H
        MOV DL, 'x'
        INT 21H
        MOV DL, 'i'
        INT 21H
        MOV DL, 't'
        INT 21H
        MOV ROW, 1
        CALL SETLO
        MOV CX, 80
LINE1:  MOV DL, '='
        INT 21H
        LOOP LINE1
        MOV ROW, 23
        CALL SETLO
        MOV CX, 80
LINE2:  MOV DL, '='
        INT 21H
        LOOP LINE2
        MOV ROW, 24
        MOV COL, 0
        CALL SETLO
        MOV AH, 02H

        ;вывод начального имени файла

        MOV DL, 'F'
        INT 21H
        MOV DL, 'i'
        INT 21H
        MOV DL, 'l'
        INT 21H
        MOV DL, 'e'
        INT 21H
        MOV DL, 'n'
        INT 21H
        MOV DL, 'a'
        INT 21H
        MOV DL, 'm'
        INT 21H
        MOV DL, 'e'
        INT 21H
        MOV DL, ':'
        INT 21H
        MOV DL, 'N'
        INT 21H
        MOV DL, 'E'
        INT 21H
        MOV DL, 'W'
        INT 21H
        MOV DL, '.'
        INT 21H
        MOV DL, 't'
        INT 21H
        MOV DL, 'x'
        INT 21H
        MOV DL, 't'
        INT 21H
        MOV ROW, 2

        RET
    MENUBAR    ENDP
    

    ;---------------------------------------
    ; Ввод (нажитие клавиш)
    ;---------------------------------------
    KEYIN    PROC    NEAR
        MOV    AH, 10H            ; Ввод клавиатура
        INT    16H                ; 
        CMP    AH, 01H            ; Клавиша ESC?
        JE     isESC              ; Нажата

        CMP    AL, 00H            ;Управляющая клавиша c мл. байтом 00h
        JE     FunKey            
        CMP    AL, 0E0H           ;Управляющая клавиша c мл. байтом E0h
        JE     Funkey               
        CALL   inChar             ; Обработать нажатие
        JMP    AllNot             ; Выйти

Funkey:
        CMP    AH, 47H            ; В меню?
        JNE    Arrdown            ; Если не равны переход к след пункт
        MOV    COL, 00            ; Столбец 0     
        JMP    AllNot             ; Выйти

Arrdown:
        CMP    AH, 50H            ; Cтрелка вниз?
        JNE    Arrup              ; Если не равны переход к след пункт
        CALL   toDown             ; Cдвиг вниз
        JMP    AllNot             ; Выйти

Arrup:  CMP    AH, 48H            ; Стрелка вверх?
        JNE    ArrR               ; Если не равны переход к след пункт
        CALL   toUp               ; Сдвиг вверх
        JMP    AllNot             ; Выйти

ArrR:   CMP    AH, 4DH            ; Стрелка вправо?
        JNE    ArrL               ; Если не равны переход к след пункт
        CALL   toR                ; Сдвиг вправо
        JMP    AllNot             ; Выйти

ArrL:   CMP    AH, 4BH            ; Стрелка влево?
        JNE    DELKey             ; Если не равны переход к след пункт
        CALL   toL                ; Сдвиг влево
        JMP    AllNot             ; Выйти


DELKey: CMP    AH, 53H            ; Удалить?
        JNE    AllNot             ; Выйти
        CALL   DELETE             ; Удалить символ

AllNot: RET
isESC:  CALL   toESC              ; Выход из меню
        RET
    KEYIN    ENDP

    ;---------------------------------------
    ; Переключение между меню-облать вода
    ;---------------------------------------
    toESC    PROC    NEAR
        MOV    COL, 00            ; Столбец 0
        CMP    ROW, 00            ; Строка 0
        JNE    TOZ
        MOV    ROW, 02            ; Вторая строка - начало области редактора
        RET
TOZ:    MOV    ROW, 00            ; Строка 0
        MOV    COL, 2             ; Столбец 2  
        RET
    toESC    ENDP
    ;---------------------------------------
    ; Конец строки
    ;---------------------------------------
    toEND    PROC    NEAR
        MOV    COL, Rlimit        ; Курсор в конец строки
        RET
    toEND    ENDP
    ;---------------------------------------
    ; Клавиша вниз
    ;---------------------------------------
    toDown    PROC    NEAR
        CMP    ROW, 00
        JE     isMenu             ; Если в меню пропустить
        CMP    ROW, Dlimit        ; Достигли низа?
        JAE    scrU               ; Прокрутить вверх на 1 строку
        INC    ROW                ; Следующая строка
isMenu: RET
    ;-----------------------------------
    ; Прокрутить вверх если курсор внизу
    ;-----------------------------------
scrU:   CMP    Ltop, CHlimit        ;
        JAE    isMenu               ; Перейти в меню если отсуп меньше или равен
        INC    Ltop                 ; Иначе увеличить Ltop +1
        MOV  AX,0601H               ; AH 06 (прокрутка)
        MOV  BH,07                  ; Нормальный атрибут (черно/белый)
        MOV     CX,0200h            ; Левая верхняя позиция
        MOV     DX,154FH            ; Правая нижняя позиция 21 строка
               INT  10H             ; Передача управления в BIOS
        CALL   SCR1                 ; Прокрутка на одну строку 
        JMP    isMenu               ; выйти
    toDown    ENDP
    ;---------------------------------------
    ; Прокрутка на одну строку
    ;---------------------------------------
    SCR1    PROC    NEAR
        PUSH   CX
        MOV    DH, ROW            ; Текущая строка 
        MOV    DL, COL            ; Текущий столбец
        PUSH   DX
        MOV    COL, 0
        CALL   Now                ; Определить позицию курсора
        CALL   SETLO              ; Установить курсор
        MOV    BX, LO             ; Подожение курсора в BX
        LEA    SI, [Str1+BX]      ; Вычислить адрес
de:     MOV    AL, [SI]           ; Символ в AL
        INC    SI                 ; Перейти к следующему символу
        CALL   aChar              ; Напечатать символ
        CMP    COL, Rlimit        ; Пока не правый предел
        JB     de
        ;-----------------------------------
        ; Вывод последнего символа
        ;-----------------------------------
        CALL   Now                ; Положение курсора в файле
        MOV    BX, LO             ; в BX
        MOV    AL, [Str1+BX]      ;Символ в AL
        MOV    AH, 09H            ; Вывод
        MOV    BH, 0
        MOV    BL, 15             ; Белый на черном фоне
        MOV    CX, 01
        INT    10H  
        POP    DX                 ; Восстановить положение курсора
        MOV    ROW, DH            ; Строку
        MOV    COL, DL            ; Столбец
        POP    CX
        RET
    SCR1    ENDP

    ;---------------------------------------
    ; Стрелка вверх
    ;---------------------------------------
    toUp    PROC    NEAR
        CMP    ROW, 00            ; Строка 0?
        JE     skip               ; 
        CMP    ROW, Tlimit        ; Предел сверху?
        JBE    scrD               ; Прокрутка вниз на одну строку
        DEC    ROW                ; уменьшить на строку
skip:
        RET
        ;-----------------------------------
        ; Прокрутка вниз когда достигнут предел сверху
        ;-----------------------------------
scrD:   CMP    Ltop, 01           ; Если в начале
        JB     skip               ; выйти
        MOV    AX, 0701H          ; Прокрутить
        DEC    Ltop               ; Уменьшить Ltop

        MOV  AX,0701H           ; AH 07 (прокрутка вниз на одну строку)
        MOV  BH,07              ; Нормальный атрибут (черно/белый)
        MOV  CX,0200h           ; Левая верхняя позиция
        MOV  DX,154FH           ; Правая нижняя позиция 21 строка
        INT  10H                ; Передача управления в BIOS

        CALL   SCR1             ; Прокрутить
        JMP    skip             ; выйти
    toUp    ENDP

    ;---------------------------------------
    ; Стрелка вправо
    ;---------------------------------------
    toR    PROC    NEAR
        CMP    COL, Rlimit        ; Предел справа?
        JAE    nextL              ; Перейти
        INC    COL                ; Увеличить на столбец
        RET
nextL:
        ;-----------------------------------
        ; Переход после достижения предела справа
        ;-----------------------------------
        CMP    Ltop, CHlimit       ; 
        JB     rightest            ; Перейти если меньше
        RET
rightest:
        MOV    COL, 00             ; Столбец 0
        CALL   toDown              ; Вниз на следующую строку
        RET
    toR    ENDP
    ;---------------------------------------
    ; Стрелка влево
    ;---------------------------------------
    toL    PROC    NEAR
        CMP    COL, Llimit        ; Предел слева?
        JBE    up                 ; Перейти
        DEC    COL                ; Уменьшить столбец
        RET
up:
        ;-----------------------------------
        ; Переход при достижении левого предела
        ;-----------------------------------
        CALL   toEND               ; В конец строки
        CALL   toUp                ; Вверх на строку
        RET
    toL    ENDP

    ;---------------------------------------
    ; Удаление
    ;---------------------------------------
    DELETE    PROC    NEAR
        MOV    BH, COL
        MOV    BL, ROW
        PUSH   BX                 ; Сохранить строку и столбец
        ; переместить данные
        CALL   Now                ; Вычислить положение указателя в файле
        MOV    BX, LO             ; Положение указателя в BX
        LEA    DI, [Str1+BX]      ; Адрес в DI 
        LEA    SI, [Str1+BX+1]    ; Адрес следующего символа в SI
reMove: MOV    AL, [SI]           ; 
        MOV    [DI], AL
        INC    SI                 ; Увелисиваем на 1
        INC    DI                 ; Увеличиваем на 1
        CALL   aChar
        CMP    COL, Rlimit        ; Правый предел?
        JB     reMove             ; Нет, повторяем
        ;-----------------------------------
        ; установка последнего символа на место пробела
        ;-----------------------------------
        CALL   Now                ; Текущее положение курсора
        MOV    BX,LO              ; в BX
        MOV    [Str1+BX], 20H     ; Записываем пробел 
        MOV    AL, 20H            ; Пробел
        MOV    AH, 09H            ; Функция вывода
        MOV    BH, 71h            ; Белый на черном
        MOV    CX, 01             ; Один символ
        INT    10H                ; Выводим пробел на экран

        POP    BX                 ; Восстановить положение курсора
        MOV    COL, BH
        MOV    ROW, BL
        RET
    DELETE    ENDP


    ;---------------------------------------
    ; Что делать в зависимости от нажатой клаиши
    ;---------------------------------------
    inChar    PROC    NEAR
        CMP    AL, 0DH            ; клавиша Enter
        JE     Ent
        CMP    ROW, 00            ; если не меню
        JE     NOChar
        CMP    AL, 08H            ; клавиша BS?
        JE     BACKSPACE

        CMP    AL, 20H            ; Если не выходит за пределы
        JB     NOChar
        CMP    AL, 7EH            
        JA     NOChar            
                                
        CALL   toChar             ; Сохраняем символ в буфер
        CALL   aChar              ; Пишем символ
NOChar:        RET

BACKSPACE:
        ;-----------------------------------
        ; Нажата клавиша BS, удаляем 
        ;-----------------------------------
        CMP    COL, 00            ; Достигли предела слева?
        JBE    NOChar
        DEC    COL                ; Уменьшить на столбец
        CALL   SETLO              ; Переместить курсор
        CALL   DELETE             ; Удаляем
        RET
repeatSpace:
        CALL   toChar             ; Сохраняем в буфер
        CALL   aChar              ; Теперь пишем пробел
        LOOP   repeatSpace
        RET
Ent:    CALL    toENTER
        RET
    inChar    ENDP
 

    ;---------------------------------------
    ; Клавиша Enter 
    ;---------------------------------------
    toENTER    PROC    NEAR
        ;-----------------------------------
        ; Создать файл
        ;-----------------------------------
        CMP    ROW, 00            ; Выбор в меню
        JNE    Lout
        CMP    COL, 05
        JA     isOPEN
        CALL CLEANSCREEN           ; Очистить экран
        CALL CLEANBUFF             ; Очистить основной буфер для текста    
        MOV    AH, 3CH             ; Создать новый файл
        CALL   File                ; Создать
        JMP    Lout

isOPEN:
        ;-----------------------------------
        ; Открыть файл
        ;-----------------------------------
        CMP    COL, 07            ; Выбор в меню
        JB     isSAVE   
        CMP    COL, 10
        JA     isSAVE

        MOV    AH, 3DH            ; Функция для работы с файлом
        CALL   File               ; Создать или открыть
        CALL   READ               ; Открыть файл


;----------------------------------------------------------------------
;Вывод файла
;---------------------------------------------------------------------
PUSH   CX
        MOV    DH, ROW            ; Текущая строка 
        MOV    DL, COL            ; Текущий столбец
        PUSH   DX   
        MOV    ROW,2              ; Строка 2
        MOV    COL, 0             ; Столбец 0
        CALL   Now                ; Определить позицию указателя
        MOV    CX,20              ; Сколько раз повторять (строки)
    cycle:    
        CALL   SETLO              ; Установить курсор
        MOV    BX, LO             ; Позиция указателя в BX
        LEA    SI, [Str1+BX]      ; Адрес в si
dee:    MOV    AL, [SI]           ; Cимвол в AL
        INC    SI                 ; Следующий

		CMP AL,0Dh  			  ; Символ новой строки
		JZ  RRR				      ; Если есть 
		CALL   aChar              ; Напечатать символ
		JMP OO 					  ; Если нет символа  прожолжаем
		RRR:
		INC LO 					  ; Пропускаем 
		INC LO 					  ; Символы в файле

		ADD    ROW,1              ; Следующая строка
		MOV    COL, 0             ; Столбец 0

		JMP EXX 			      ; Следующая итерация
 		OO:
 		INC LO
        CMP    COL, Rlimit        ; Пока не предел справа
        JB     dee
        ; Последний символ
        CALL   Now                ; Определить позицию указателя
        PUSH   CX
        MOV    BX, LO             ; Позиция указателя в BX
        MOV    AL, [Str1+BX]      ; Символ в AL
        MOV    AH, 09H            ; Функция вывода
        MOV    BH, 0 
        MOV    BL, 15             ; Белый на черном фоне
        MOV    CX, 01             ; Один символ
        INT    10H                ; Вывести
        ADD    ROW,1              ; Следующая строка
        MOV    COL, 0             ; Столбец 0
        pop cx
exx:        
        loop cycle                ; Цикл


        POP    DX                 ; Восстановить положение курсора
        MOV    ROW, DH
        MOV    COL, DL
        POP    CX

;-------------------------------------------------------------------
        JMP    Lout

isSAVE:
        ;-----------------------------------
        ; Save
        ;-----------------------------------
        CMP    COL, 12            ; Выбор в меню
        JB     Exit
        CMP    COL, 15
        JA     Exit
        CALL   write              ; Сохранить в буфер
        CALL   close              ; Закрыть файл
        JMP    Lout

EXIT:   
        CMP    COL, 17            ; Выбор в меню
        JB     Lout
        CMP    COL, 20
        JA     Lout
        CALL   close              ; Закрыть файл

            MOV  AX,0600H         ;AH 06 (прокрутка)
                                  ;AL 00 (весь экран)
            MOV  BH,07            ;Нормальный атрибут (черно/белый)
            MOV  CX,0000          ;Верхняя левая позиция
            MOV  DX,184FH         ;Нижняя правая позиция
            INT  10H       

        MOV    AX, 4C00H          ; Выход из программы
        INT    21H
        RET
Lout:  MOV    COL, 00             ; Столбец 0
        CALL   todown
        RET
    toENTER    ENDP
    ;---------------------------------------
    ; Сохранить данные в буфер Str1
    ;---------------------------------------
    toChar    PROC    NEAR
        PUSH   AX
        CALL   Now                ; Положение курсора для сохраниния
        MOV    BX, LO             ; Переместить в BX
        LEA    DI, Str1           ; Адрес буфера
        MOV    [DI+BX], AL        ; Переместить данные в str1
        POP    AX
        RET
    toChar    ENDP
    ;---------------------------------------
    ; Текущее положение курсора
    ;---------------------------------------
    Now    PROC    NEAR
        PUSH   CX                                 
        PUSH   DX

        MOV    LO, 00             ; Сброс LO
        MOVZX  CX, ROW            ; Строка в CX
        DEC    CX                 ; Уменьшить cx 
        DEC    CX                 ; Уменьшить cx
        MOVZX  DX, Ltop           ; На сколько прокрутить
        ADD    CX, DX             ; Строка
        CMP    CX, 01             ; Первая строка?
        JB     addCOL             ; Добавить столбец

addROW: add    LO, 80             ; Переходим на нужную строку 
        LOOP   addROW
        
addCOL: MOVZX  DX, COL            ; Переходим в нужный столбец
        add    LO, DX

        POP    DX
        POP    CX
        RET
    Now    ENDP
    ;---------------------------------------
    ; Написать символ
    ;---------------------------------------
    aChar    PROC    NEAR
        PUSH   AX
        PUSH   CX
        MOV    AH, 09H             ; Функция записи символа на месте курсора
         MOV   BH, 00              ; Атрибут цвета!
        MOV    BL, 15              ; Атрибут цвета
        MOV    CX, 1               ; Один символ
        INT    10H                  

OK:     CALL   toR                 ; Курсор вправо
        CALL   SETLO               ; Переместить
        POP    CX
        POP    AX
        RET
    aChar    ENDP

    ;---------------------------------------
    ; Указатель в начало файла
    ;---------------------------------------
    RETURNFILE PROC 
    PUSH CX
        PUSH DX
        CALL SETLO             ; Переместить курсор в начало меню
        MOV AX,4201h           ; Переместить указатель файла от текущей позиции
        MOV DX,-8000           ; на 8000 байт назад
        MOV CX,-1 
        int 21h
        POP DX
        POP CX
    RET
    RETURNFILE ENDP
        ;-----------------------------------
        ; Очистить буфер имени файла
        ;-----------------------------------
        CLEANBUF PROC NEAR
        PUSH CX
        MOV CX, 23           ; Сколько очистить
        MOV SI, 0000         ; Начинаем сначала
CLEAN:  MOV INDATA1[SI], 20H ; Заменяем пробелами
        INC SI               ; Переход к следующему
        LOOP CLEAN           ; в цикл
        POP CX
        RET
        CLEANBUF ENDP

;-------------------------------------
;Прокрутить экран и очистить после сохранения
;-------------------------------------
CLEANSCREEN PROC NEAR
            PUSH AX
            PUSH CX
            MOV  AX,0614H  ;AH 06 (прокрутка)
                           ;AL на 20 строк 
            MOV  BH,07     ;Нормальный атрибут (черно/белый)
            MOV  CX,0200H  ;Верхняя левая позиция
            MOV  DX,154FH  ;Нижняя правая позиция
            INT  10H
            POP CX 
            POP AX
           RET
CLEANSCREEN ENDP

    ;---------------------------------------
    ; Переместить курсор
    ;---------------------------------------
    SETLO    PROC    NEAR
        MOV    AH, 02H      ;Установить позицию курсора        
        MOV    BH, 00
        MOV    DH, ROW      ; Строка
        MOV    DL, COL      ; Столбец
        INT    10H          ; Установить    
        RET
    SETLO    ENDP  
    ;------------------------------------- 
    ;Очистить основной буфер данных
    ;--------------------------------------
CLEANBUFF PROC NEAR
        PUSH CX                ; Сохранить CX
        MOV CX, 8000           ; Сколько очистить
        MOV SI, 0              ; Начинаем сначала
Cll:  MOV Str1[SI], 20H        ; Заменяем пробелами
        INC SI                 ; К следующему
        LOOP Cll               ; Цикл
        POP CX
        RET
CLEANBUFF ENDP
END 