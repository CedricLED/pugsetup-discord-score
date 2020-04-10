const config = require('./config.json');
const Client = require('eris');
const _ = require('lodash');
const express = require('express');
const helmet = require('helmet');
const bodyParser = require('body-parser');
const Rcon = require('srcds-rcon');
const rcon = Rcon({
    address: '192.223.26.32',
    password: '80percent'
});

const steamIDLib = require('steamid');

const bot = new Client(config.token);
const app = express();

const port = process.env.PORT || 3001;

app.use(helmet());

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
  extended: true,
}));


app.post('/', (req, res) => {
  const { body } = req;

  if (_.has(body, 'pass') === false) {
    return res.send('Failure');
  }

  if (body.pass !== config.pass) {
    return res.send('Failure');
  }

  if (body.state === 'result') {
    let tscore = body.tscore;
    let ctscore = body.ctscore;
    let tname = body.tname;
    let ctname = body.ctname;
    gameresult(tname, ctname, tscore, ctscore);
  }

  res.send('Success');
});

bot.on('ready', startExpress);

function startExpress() {
  app.listen(port, 'localhost', () => {
    console.log(`listening on port ${port}!`);
  });
}

bot.on("messageCreate", (msg) => {
  if(msg.channel.id === config.botchat) {
    if(msg.content === "!score") {
      rcon.connect().then(() => {
        rcon.command('getpugscore').then(result => {
          let command = result.split("L");
          let res = command.split(",");
          if (res[0] + res[1] < 15) {
            bot.createMessage(msg.channel.id, `T score: ${res[0]}, CT score: ${res[1]}`);
          } else {
            bot.createMessage(msg.channel.id, `CT score: ${res[0]}, T score: ${res[1]}`);
          }
        }).then(
          () => rcon.disconnect()
        ).catch(err => {
          console.log('caught', err);
          console.log(err.stack);
        });
      });
    }
  }
});

bot.on("messageCreate", (msg) => {
  if(msg.content === "!score") {
    if(msg.channel.id !== config.botchat) {
      msg.author.getDMChannel().then(UserDM => {
        UserDM.createMessage('!score is a #10-man only command!');
      }).then(() => {
        msg.delete();
      });
    }
  }
});

function gameresult(tname, ctname, tscore, ctscore) {
  if (tscore > ctscore) {
    let res = (`${tname} Beat ${ctname} ${tscore}:${ctscore}`);
    bot.createMessage(config.gameresult, res);
  } else {
    let res = (`${ctname} Beat ${tname} ${ctscore}:${tscore}`);
    bot.createMessage(config.gameresult, res);
  }
}

bot.connect();
