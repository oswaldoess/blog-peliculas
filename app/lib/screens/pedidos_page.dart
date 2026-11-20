import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/tienda_model.dart';
import '../services/tienda_service.dart';
import '../utils/formatos.dart';
import '../widgets/estado_vista.dart';

/// Historial de compras del usuario.
class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  late Future<List<PedidoModel>> _futuro = TiendaService().misPedidos();

  void _recargar() => setState(() => _futuro = TiendaService().misPedidos());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis compras')),
      body: FutureBuilder<List<PedidoModel>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return EstadoVista.error(snapshot.error!, _recargar);
          final pedidos = snapshot.data ?? const <PedidoModel>[];
          if (pedidos.isEmpty) {
            return const EstadoVista(
              icono: Icons.receipt_long_outlined,
              titulo: 'Todavía no tienes compras',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length,
            itemBuilder: (context, i) {
              final p = pedidos[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const Icon(Icons.receipt_long, color: AppColors.azul),
                  title: Text(p.referencia, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${Formatos.fecha(p.fecha)} · ${p.marca} •••• ${p.ultimos4}'),
                  trailing: Text(
                    formatoPrecio(p.total),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.marino),
                  ),
                  children: p.detalles
                      .map((d) => ListTile(
                            dense: true,
                            title: Text(d.nombre),
                            trailing: Text('${d.cantidad} × ${formatoPrecio(d.precioUnit)}'),
                          ))
                      .toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
