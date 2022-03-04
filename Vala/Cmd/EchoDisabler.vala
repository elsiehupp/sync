/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Heule <daniel.heule@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

using Occ;

class EchoDisabler {

    /***********************************************************
    ***********************************************************/
    public EchoDisabler () {
        tcgetattr (STDIN_FILENO, tios);
        termios tios_new = tios;
        tios_new.c_lflag &= ~ECHO;
        tcsetattr (STDIN_FILENO, TCSANOW, tios_new);
    }

    ~EchoDisabler () {
        tcsetattr (STDIN_FILENO, TCSANOW, tios);
    }


    /***********************************************************
    ***********************************************************/
    private termios tios;
}