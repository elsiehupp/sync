/***********************************************************
@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Heule <daniel.heule@gmail.com>
@copyright GPLv3 or Later
***********************************************************/

public class EchoDisabler {

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