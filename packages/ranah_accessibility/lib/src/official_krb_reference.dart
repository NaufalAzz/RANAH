import 'volcano_reference.dart';

/// Official raster maps supplement reports without bundled vector geometry.
/// These images are documents, not georeferenced overlays.
class OfficialKrbReference {
  const OfficialKrbReference(this.name, this.year, this.imageUrl);
  final String name;
  final int year;
  final String imageUrl;
  static const source = 'PVMBG / MAGMA Indonesia';
  static const catalogUrl =
      'https://magma.esdm.go.id/v1/gunung-api/peta-kawasan-rawan-bencana';
  static const checkedAt = '2026-11-21';
}

OfficialKrbReference? officialKrbReference(String name) =>
    officialKrbReferences[normalizeVolcanoName(name)];

const officialKrbReferences = <String, OfficialKrbReference>{
  'ambang': OfficialKrbReference(
    "Ambang",
    2007,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/zt9SBVb0hAELeV8PL4JllkTL74ScgXJwE7Fx0qOE.jpg",
  ),
  'anakkrakatau': OfficialKrbReference(
    "Anak Krakatau",
    2007,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/gZcXl6jpyIKxuoUy5sNLEO2pGFXv3HHMHqNacuKw.jpg",
  ),
  'anakranakah': OfficialKrbReference(
    "Anak Ranakah",
    2010,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/gZhiVI0gFHTWrAUgUuE2v3evRRNS12dFiWaKZFKr.jpg",
  ),
  'arjunowelirang': OfficialKrbReference(
    "Arjuno Welirang",
    2009,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/nv7BzPPJtYdUM8uoWHehPyv9qnVi2RtyqZlWn674.jpg",
  ),
  'bandaapi': OfficialKrbReference(
    "Banda Api",
    2008,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/fmdRe1bCXuOHc4yUpn8AUHJEAMclnq7QLyL9UNlf.jpg",
  ),
  'batutara': OfficialKrbReference(
    "Batutara",
    2012,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/ploto7aeA4rsWvBgaVifCxjhX3vn5kfcZGR3lA09.jpg",
  ),
  'burnitelong': OfficialKrbReference(
    "Bur Ni Telong",
    2008,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/y8shVhAWclLZ9myVQFRHkZCmzLDTkitCFqP9cYR3.jpg",
  ),
  'ciremai': OfficialKrbReference(
    "Ciremai",
    2006,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/Md4LPOs7BJqcAl0L7KmbIMH9xiLa6PG7W5a97MU4.jpg",
  ),
  'dempo': OfficialKrbReference(
    "Dempo",
    2009,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/KvFe4MNA7al59Kye8Rnw6bw3U1KnFDMxYMHst7nA.jpg",
  ),
  'dieng': OfficialKrbReference(
    "Dieng",
    2011,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/02JNV19EQhhQvckbYEX8kQQ9Qdh91Od7xE4EzBtJ.jpg",
  ),
  'dukono': OfficialKrbReference(
    "Dukono",
    2008,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/dnrh2FlNqRpYTrcI2A9MovyfEWlCH03PTuHS5zVC.jpg",
  ),
  'ebulobo': OfficialKrbReference(
    "Ebulobo",
    2007,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/2epN0hpQ9ISqEWL081TnUr113P2ldABNtEkzzuAx.jpg",
  ),
  'egon': OfficialKrbReference(
    "Egon",
    2005,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/RkO0i70BkkPnCmUInWmHx5TtWRaIFncs5gpQsIx3.jpg",
  ),
  'gamalama': OfficialKrbReference(
    "Gamalama",
    1996,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/zpnkYXAs2F0hNPb0zsuThek8c99VlLjiJayriIh2.jpg",
  ),
  'gamkonora': OfficialKrbReference(
    "Gamkonora",
    2006,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/1Ba7X6rPddtwRVKPUhV7r9ahwTTlbvsilLdoEvyd.jpg",
  ),
  'guntur': OfficialKrbReference(
    "Guntur",
    2015,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/9VM69VpLBlajiiHVOiEUoYtyac3y5xnC3dX7ihTj.jpg",
  ),
  'ibu': OfficialKrbReference(
    "Ibu",
    2008,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/ShTymO274gJv2acx33v2f42ZOJbyxID8kyPbeJEl.jpg",
  ),
  'ilewerung': OfficialKrbReference(
    "Ile Werung",
    2010,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/JCyXcFjwJ8AUBhntjeHD6IMdh86wh4D1NlyEQ5Yz.jpg",
  ),
  'ililewotolok': OfficialKrbReference(
    "Ili Lewotolok",
    2010,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/bHUucHe5NlaC8pXrdqjx9jERaZ7D7FEnVLC2zgio.jpg",
  ),
  'inielika': OfficialKrbReference(
    "Inielika",
    2009,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/mXzJkg30XCohSBiLUqOLIACHfaKRIQmkv4jveGQY.jpg",
  ),
  'inierie': OfficialKrbReference(
    "Inierie",
    2009,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/FwUs4hy5AR78PrqVxKYQdIOM62hKtWqWF85tUbjn.jpg",
  ),
  'iya': OfficialKrbReference(
    "Iya",
    2010,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/A1ZLbjwz186uGzUSA5JMnHjCTqAdQ1d4u8cRaR3h.jpg",
  ),
  'kaba': OfficialKrbReference(
    "Kaba",
    2008,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/o2MWHIoDnuUbdBwuqwueDqsIw5mfjbPm1ys7iqsV.jpg",
  ),
  'karangetang': OfficialKrbReference(
    "Karangetang",
    2011,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/tkkreoklnvg0rKZoDXpSwHXyXyyxdyU1wXxavM7g.jpg",
  ),
  'kerinci': OfficialKrbReference(
    "Kerinci",
    2014,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/LDQsLeFweLqQ8EJFOgi5lS6HrYtZMvEuIDtcYKDk.jpg",
  ),
  'kiebesi': OfficialKrbReference(
    "Kie Besi",
    2008,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/6xVFBRhTM5pmMnnH4WAfn8rexrInwcNoQ7doekHp.jpg",
  ),
  'lereboleng': OfficialKrbReference(
    "Lereboleng",
    2010,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/PtbL89BKqAAbR01lK6HT9iGDiPvrF4AYRzYOrbkv.jpg",
  ),
  'lewotobilakilaki': OfficialKrbReference(
    "Lewotobi Laki-laki",
    2009,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/wEPzhwq0VZM5ob0bNp0lrwtXFafeYac0YjPiwNBa.jpg",
  ),
  'mahawu': OfficialKrbReference(
    "Mahawu",
    2007,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/a7xi8pydbwqgzjtVEU39sIlLh5HALALe6iqwObfz.jpg",
  ),
  'papandayan': OfficialKrbReference(
    "Papandayan",
    2010,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/nXWFLWtTw3YSzTmf6GvaCpqbujLmtZpOUFAmXh0I.jpg",
  ),
  'peutsague': OfficialKrbReference(
    "Peut Sague",
    2007,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/a1K7nmV5NLNTbJzon6BamhjqLFnLoIQpQjzQIy5d.jpg",
  ),
  'ruang': OfficialKrbReference(
    "Ruang",
    2007,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/d5GmZVaexkPCSdoZP9mrKLLJ6xcf8fyvLfFk1PlX.jpg",
  ),
  'salak': OfficialKrbReference(
    "Salak",
    2006,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/QkAfabi51oFdB9pbCqMQyf7yBkvn7JnV4Jdy4xZ3.jpg",
  ),
  'seulawahagam': OfficialKrbReference(
    "Seulawah Agam",
    2007,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/DmuA537LLbLXfksx5MRgtmznVcVN7YXnhjq3rqXm.jpg",
  ),
  'soputan': OfficialKrbReference(
    "Soputan",
    2006,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/kNYJNcrhiSII6WBWrw1h0dbNkRafyip0l0Fl5eJu.jpg",
  ),
  'sorikmarapi': OfficialKrbReference(
    "Sorikmarapi",
    2008,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/wFYIBbiESDhD8OttzeykajGRoZfdlDEpa8wemes3.jpg",
  ),
  'sumbing': OfficialKrbReference(
    "Sumbing",
    2006,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/Yiob7nEKiY4Z5bYs0qWDVtuuW9imN9xn9inC30Wy.jpg",
  ),
  'sundoro': OfficialKrbReference(
    "Sundoro",
    2007,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/7aswqbvkI6n6xTaoWg8iSjKsN3AbQU4rW0XsTHsq.jpg",
  ),
  'tangkoko': OfficialKrbReference(
    "Tangkoko",
    2010,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/EMVdWYpTgVI9jkYYAH9de9JyqNMNizotVzADGxYv.jpg",
  ),
  'wurlali': OfficialKrbReference(
    "Wurlali",
    2010,
    "https://magma.esdm.go.id/storage/krb-gunungapi/large/PeORaMUTWrs20XyCA0hPcGLBOJC4uhkuGmxb5PHU.jpg",
  ),
};
