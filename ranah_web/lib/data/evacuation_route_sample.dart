/// Route values used only to demonstrate the evacuation route UI.
/// They are not verified guidance or current road information.
class EvacuationRouteSample {
  const EvacuationRouteSample({
    required this.hazard,
    required this.origin,
    required this.destination,
    required this.distance,
    required this.walkingEstimate,
  });

  final String hazard;
  final String origin;
  final String destination;
  final String distance;
  final String walkingEstimate;
}

const sampleEvacuationRoute = EvacuationRouteSample(
  hazard: 'Tsunami · simulasi',
  origin: 'Universitas Negeri Padang (contoh)',
  destination: 'Titik aman ilustratif · Jl. Bypass',
  distance: '±4,2 km · simulasi',
  walkingEstimate: '±55 menit · simulasi',
);
