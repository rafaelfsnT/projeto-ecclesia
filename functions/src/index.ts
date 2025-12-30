import * as admin from "firebase-admin";
import { onCall, HttpsError, HttpsOptions } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

admin.initializeApp();

const functionOptions: HttpsOptions = {
  region: "southamerica-east1",
  memory: "256MiB",
};

async function verifyIsAdmin(uid: string): Promise<void> {
  const userDoc = await admin.firestore().collection("usuarios").doc(uid).get();
  if (!userDoc.exists || userDoc.data()?.role !== 'admin') {
    throw new HttpsError("permission-denied", "Ação permitida apenas para administradores.");
  }
}

export const enableUser = onCall(functionOptions, async (request) => { // <-- REGIÃO APLICADA
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Você precisa estar logado para realizar esta ação.");
  }
  await verifyIsAdmin(request.auth.uid);

  const targetUid = request.data.uid;
  if (!targetUid || typeof targetUid !== "string") {
    throw new HttpsError("invalid-argument", "O UID do usuário alvo é necessário.");
  }

  try {
    const promises = [
      admin.auth().updateUser(targetUid, { disabled: false }),
      admin.firestore().collection("usuarios").doc(targetUid).update({ ativo: true }),
    ];
    await Promise.all(promises);

    return { success: true, message: "Usuário ativado com sucesso." };
  } catch (error) {
    console.error("Erro ao ativar usuário:", error);
    throw new HttpsError("internal", "Ocorreu um erro ao ativar o usuário.");
  }
});

export const disableUser = onCall(functionOptions, async (request) => { // <-- REGIÃO APLICADA
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Você precisa estar logado para realizar esta ação.");
  }
  await verifyIsAdmin(request.auth.uid);

  const targetUid = request.data.uid;
  if (!targetUid || typeof targetUid !== "string") {
    throw new HttpsError("invalid-argument", "O UID do usuário alvo é necessário.");
  }

  try {
    const promises = [
      admin.auth().updateUser(targetUid, { disabled: true }).catch((error: any) => {
        if (error.code !== "auth/user-not-found") throw error;
      }),
      admin.firestore().collection("usuarios").doc(targetUid).update({ ativo: false }),
    ];
    await Promise.all(promises);

    return { success: true, message: "Usuário desativado com sucesso." };
  } catch (error) {
    console.error("Erro ao desativar usuário:", error);
    throw new HttpsError("internal", "Ocorreu um erro ao desativar o usuário.");
  }
});

export const deleteUser = onCall(functionOptions, async (request) => { // <-- REGIÃO APLICADA
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Você precisa estar logado para realizar esta ação.");
  }
  await verifyIsAdmin(request.auth.uid);

  const targetUid = request.data.uid;
  if (!targetUid || typeof targetUid !== "string") {
    throw new HttpsError("invalid-argument", "O UID do usuário alvo é necessário.");
  }

  try {
    const firestore = admin.firestore();

    // --- LÓGICA DE LIMPEZA ADICIONADA AQUI ---
    console.log(`Iniciando limpeza de escalas para o usuário a ser deletado: ${targetUid}`);
    const now = admin.firestore.Timestamp.now();
    const futureMassesSnapshot = await firestore.collection('missas').where('dataHora', '>=', now).get();

    const cleanupPromises: Promise<any>[] = [];

    futureMassesSnapshot.forEach(doc => {
      const escala = doc.data().escala as { [key: string]: string | null };
      const updatePayload: { [key: string]: any } = {};
      let needsUpdate = false;

      for (const cargoKey in escala) {
        if (escala[cargoKey] === targetUid) {
          updatePayload[`escala.${cargoKey}`] = null;
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        console.log(`Agendando limpeza do UID ${targetUid} na missa ${doc.id}`);
        cleanupPromises.push(doc.ref.update(updatePayload));
      }
    });
    // Fim da lógica de limpeza

    // Lógica original de deleção
    const deletionPromises = [
      admin.auth().deleteUser(targetUid).catch((error: any) => {
        if (error.code !== "auth/user-not-found") throw error;
        console.log(`Usuário ${targetUid} não encontrado no Auth, continuando.`);
      }),
      firestore.collection("usuarios").doc(targetUid).delete(),
    ];

    // Combina todas as operações (limpeza e deleção) para serem executadas em paralelo
    const allPromises = [...cleanupPromises, ...deletionPromises];
    await Promise.all(allPromises);

    return { success: true, message: "Usuário e todos os seus vínculos de escala foram removidos com sucesso." };
  } catch (error) {
    console.error("Erro ao deletar usuário e limpar vínculos:", error);
    throw new HttpsError("internal", "Ocorreu um erro ao deletar o usuário.");
  }
});

export const criarNovoUsuarioAdmin = onCall(functionOptions, async (request) => {
   console.log("Chamada recebida. Auth object:", request.auth);
     console.log("UID do usuário logado:", request.auth ? request.auth.uid : "NULO");
    // <-- REGIÃO APLICADA
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Usuário não autenticado."
    );
  }

  await verifyIsAdmin(request.auth.uid);

    const email = request.data.email;
    const password = request.data.password;
    const name = request.data.name;
    const categories = request.data.categories;
    const idGrupoMusical = request.data.idGrupoMusical;
    const idGrupoCoordenado = request.data.idGrupoCoordenado;

    // Validação básica dos dados recebidos
    if (!email || !password || !name) {
      throw new HttpsError("invalid-argument", "Email, senha e nome são obrigatórios.");
    }

    try {
      const userRecord = await admin.auth().createUser({
        email: email,
        password: password,
        displayName: name,
        emailVerified: false, // O usuário verifica depois, no login
      });

      const uid = userRecord.uid;

      await admin.firestore().collection("usuarios").doc(uid).set({
        nome: name,
        email: email,
        role: "user", // Define a role padrão
        categorias: categories,
        ativo: true,
        criadoEm: admin.firestore.FieldValue.serverTimestamp(),
        idGrupoMusical: idGrupoMusical || null,
        idGrupoCoordenado: idGrupoCoordenado || null,
      });

      return { status: "success", uid: uid };

    } catch (error) {
      console.error("Erro ao criar usuário:", error);

      let errorMessage = "Ocorreu um erro ao criar o usuário.";
      if (error instanceof Error) {
        errorMessage = error.message;
      }

      throw new HttpsError("internal", errorMessage);
    }
  }
);

export const onNewEventCreated = onDocumentCreated(
  {
    document: "eventos/{eventoId}",
    region: "southamerica-east1",
    memory: "256MiB",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const evento = snapshot.data();
    if (!evento) return;

    const titulo = evento.titulo || "Novo Evento";
    const local = evento.local || "Confira no app";

    console.log(`Novo evento: ${titulo}. Enviando notificações...`);
    const db = admin.firestore();
    // 1. Prepara a "carga" da notificação (o payload)
    const payload = {
      notification: {
        title: "🎉 Novo Evento na Paróquia!",
        body: `${titulo} \nLocal: ${local}. Toque para ver os detalhes!`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        screen: "/all-events",
        id: event.params.eventoId,
      },
    };

   const notificacaoData = {
         titulo: payload.notification.title,
         corpo: payload.notification.body,
         data: admin.firestore.FieldValue.serverTimestamp(), // Data de criação
         lida: false, // Começa como "não lida"
         tipo: "evento", // Para sabermos onde navegar
         documentId: event.params.eventoId, // O ID do evento
       };

       try {
         // 3. Busca TODOS os usuários
         const usersSnapshot = await db.collection("usuarios").get();
         const tokens: string[] = [];
         const writePromises: Promise<any>[] = [];

         usersSnapshot.forEach(userDoc => {
           const userData = userDoc.data();
           const isNotAdmin = userData.role !== 'admin';
          if (isNotAdmin) {
                if (userData.fcmToken) {
                  tokens.push(userData.fcmToken);
                }
           // Adiciona a promessa de salvar a notificação na subcoleção dele
           writePromises.push(
             userDoc.ref.collection("notificacoes").add(notificacaoData)
           );
       }
         });

         console.log(`Salvando ${writePromises.length} documentos de notificação...`);
         await Promise.all(writePromises);
         console.log("Documentos de notificação salvos.");

       if (tokens.length > 0) {
           // 5. Envia o push APENAS para os tokens filtrados (não admins)
           await admin.messaging().sendEachForMulticast({ tokens, ...payload });
           console.log(`Notificações enviadas para ${tokens.length} usuários (Admins ignorados).`);
         } else {
           console.log("Nenhum usuário elegível para receber notificação.");
         }
       } catch (error) {
         console.error("Erro ao enviar notificações de evento:", error);
       }
     }
   );

export const enviarLembretesProgramados = onSchedule(
  {
    schedule: "0 8 * * *", // Todo dia às 8:00
    timeZone: "America/Sao_Paulo",
    region: "southamerica-east1",
    memory: "256MiB",
  },
  async (event) => {
    console.log("Iniciando função de lembretes programados...");

    const agora = new Date();
    const limiteTempo = new Date(agora.getTime() + 48 * 60 * 60 * 1000);
    const db = admin.firestore();
    const tokens: { [uid: string]: string } = {};

    try {
      const missasSnap = await db.collection("missas")
        .where("dataHora", ">=", agora)
        .where("dataHora", "<=", limiteTempo)
        .get();

      console.log(`Encontradas ${missasSnap.docs.length} missas próximas.`);

      const promises = missasSnap.docs.map(async (doc) => {
        const missa = doc.data();
        const escala = missa.escala as { [key: string]: string | null };

        if (!escala) return;

        const dataMissa = (missa.dataHora as admin.firestore.Timestamp)
          .toDate()
          .toLocaleDateString("pt-BR", {
            day: "2-digit", month: "2-digit", hour: "2-digit", minute: "2-digit",
          });

        for (const [cargo, uid] of Object.entries(escala)) {
          if (uid) {
            try {
              if (!tokens[uid]) {
                const userDoc = await db.collection("usuarios").doc(uid).get();
                tokens[uid] = userDoc.data()?.fcmToken;
              }

              const token = tokens[uid];

              // [CORREÇÃO] Definição das variáveis que faltavam
              const tituloNotif = "🔔 Lembrete de Escala";
              const corpoNotif = `Você está escalado(a) para: ${formatarCargo(cargo)} na missa do dia ${dataMissa}.`;

              // 1. Prepara o payload do push
              const payload = {
                notification: {
                  title: tituloNotif,
                  body: corpoNotif,
                },
                data: { // Dados para navegação no app
                  click_action: "FLUTTER_NOTIFICATION_CLICK",
                  screen: `/missa/${doc.id}`,
                  id: doc.id,
                },
              };

              // 2. Prepara o documento a ser salvo no Firestore
              const notificacaoData = {
                titulo: tituloNotif, // <-- Agora funciona
                corpo: corpoNotif,   // <-- Agora funciona
                data: admin.firestore.FieldValue.serverTimestamp(),
                lida: false,
                tipo: "missa",
                documentId: doc.id,
              };

              // 3. Salva o registro no Firestore
              await db.collection("usuarios").doc(uid).collection("notificacoes").add(notificacaoData);

              // 4. Se o usuário tiver um token, envia o push
              if (token) {
                const messageToSend = {
                  ...payload,
                  token: token,
                };
                await admin.messaging().send(messageToSend);
                console.log(`Lembrete de escala enviado para UID ${uid}`);
              }

            } catch (err) {
              console.error(`Erro ao enviar lembrete para UID ${uid}:`, err);
            }
          }
        }
      });

      await Promise.all(promises);

    } catch (error) {
      console.error("Erro ao processar lembretes de escala:", error);
    }

    console.log("Função de lembretes finalizada.");
  }
);

// Função helper (sem alteração)
function formatarCargo(cargoKey: string): string {
  switch (cargoKey) {
    case "comentarista": return "Comentarista";
    case "preces": return "Preces";
    case "ministro1": return "Ministro 1";
    case "ministro2": return "Ministro 2";
    case "ministro3": return "Ministro 3";
    case "primeiraLeitura": return "1ª Leitura";
    case "segundaLeitura": return "2ª Leitura";
    case "salmo": return "Salmo";
    default: return cargoKey;
  }
}


export const notificarAgendaMensal = onCall(functionOptions, async (request) => {
  // 1. Segurança: Verifica se é Admin
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado.");
  }
  await verifyIsAdmin(request.auth.uid);

  const nomeMes = request.data.nomeMes; // Ex: "Dezembro"
  const ano = request.data.ano;         // Ex: 2025

  if (!nomeMes || !ano) {
    throw new HttpsError("invalid-argument", "Mês e Ano são obrigatórios.");
  }

  console.log(`Iniciando notificação de agenda para: ${nomeMes}/${ano}`);
  const db = admin.firestore();

  // 2. Prepara a mensagem
  const tituloNotif = `📅 Agenda de ${nomeMes} Disponível!`;
  const corpoNotif = `As missas para o mês de ${nomeMes} de ${ano} já foram cadastradas. Toque para conferir os horários.`;

  const payload = {
    notification: {
      title: tituloNotif,
      body: corpoNotif,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      screen: "/todas-missas", // Leva para a lista de missas
    },
  };

  // Objeto para histórico
  const notificacaoData = {
    titulo: tituloNotif,
    corpo: corpoNotif,
    data: admin.firestore.FieldValue.serverTimestamp(),
    lida: false,
    tipo: "aviso_agenda",
    documentId: null, // Aviso geral, não liga a uma missa específica
  };

  try {
    // 3. Lógica de Envio (Idêntica à de eventos/missas)
    const usersSnapshot = await db.collection("usuarios").get();
    const tokens: string[] = [];
    const writePromises: Promise<any>[] = [];

    usersSnapshot.forEach(userDoc => {
      const userData = userDoc.data();
      const isNotAdmin = userData.role !== 'admin';

      if (isNotAdmin) {
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
        // Salva histórico
        writePromises.push(
          userDoc.ref.collection("notificacoes").add(notificacaoData)
        );
      }
    });

    await Promise.all(writePromises);

    if (tokens.length > 0) {
      await admin.messaging().sendEachForMulticast({ tokens, ...payload });
      return { success: true, message: `Notificação enviada para ${tokens.length} usuários.` };
    } else {
      return { success: true, message: "Nenhum usuário para notificar." };
    }

  } catch (error) {
    console.error("Erro ao notificar agenda:", error);
    throw new HttpsError("internal", "Erro ao processar envio.");
  }
});