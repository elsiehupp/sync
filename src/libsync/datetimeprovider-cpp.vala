
namespace Occ {

DateTimeProvider.~DateTimeProvider () = default;

QDateTime DateTimeProvider.currentDateTime () {
    return QDateTime.currentDateTime ();
}

QDate DateTimeProvider.currentDate () {
    return QDate.currentDate ();
}

}
