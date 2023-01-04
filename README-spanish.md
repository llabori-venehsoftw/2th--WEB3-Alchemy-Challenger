# Solution al desafio #2 Universidad de Alchemy

Objetivos:
Al final de este tutorial, aprenderás a hacer lo siguiente:

    * Utilizar el entorno de desarrollo Hardhat para construir, probar y desplegar nuestro contrato
      inteligente.
    * Conectar tu billetera MetaMask a la red de prueba Goerli utilizando un punto final RPC Alchemy.
    * Obtén Goerli ETH gratis de goerlifaucet.com.
    * Utiliza Ethers.js para interactuar con tu contrato inteligente.
    * Construir un sitio web frontend para su aplicación descentralizada con Replit.

## Iniciando 🚀

Estas instrucciones te permitirán tener una copia del proyecto corriendo en tu máquina local para
propósitos de desarrollo y pruebas.

Ver **Despliegue** para saber cómo desplegar el proyecto.

### Prerrequisitos 📋

Para prepararte para el resto de este tutorial, necesitas tener:

    npm (npx) versión 8.5.5
    node versión 16.13.1
    Una cuenta de Alchemy (¡regístrate aquí gratis!)

Lo siguiente no es necesario, pero es extremadamente útil:

    cierta familiaridad con la línea de comandos
    cierta familiaridad con JavaScript

Ahora vamos a empezar a construir nuestro contrato inteligente

### Instalación 🔧

_Codifica el contrato inteligente BuyMeACoffee.sol_

Abre tu terminal y crea un nuevo directorio:

```
mkdir BuyMeACoffee-contratos
cd Contratos-ComprameACoffee
```

inicia un nuevo proyecto npm (la configuración por defecto está bien):

```
npm init -y
```

Esto debería crear un archivo package.json para usted que se parece a esto:

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npm init
-y
Wrote to ~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$/package.json:

{
  "name": "buymeacoffee-contracts",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
```

Instalar hardhat:

```
npm install --save-dev hardhat
```

Crear un proyecto de ejemplo:

```
npx hardhat
```

Pulsa Enter para aceptar todos los ajustes por defecto e instalar las dependencias del proyecto de
ejemplo.

El directorio de tu proyecto debería tener ahora este aspecto (Utiliza el árbol para visualizarlo):

```
llabori@Xubuntu64Bits-máquina-virtual:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ tree -C
-L 1
```

![Alt text](https://www.github.com/assets.digitalocean.com/articles/alligator/boo.svg "un título")

Cambia el nombre del archivo del contrato a BuyMeACoffee.sol

Sustituye el código del contrato por lo siguiente:

```
//SPDX-License-Identifier: Unlicense

// contracts/BuyMeACoffee.sol
pragma solidity ^0.8.0;

// Switch this to your own contract address once deployed, for bookkeeping!
// Example Contract Address on Goerli: 0xDBa03676a2fBb6711CB652beF5B7416A53c1421D

contract BuyMeACoffee {
    // Event to emit when a Memo is created.
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    // Memo struct.
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // Address of contract deployer. Marked payable so that
    // we can withdraw to this address later.
    address payable owner;

    // List of all memos received from coffee purchases.
    Memo[] memos;

    constructor() {
        // Store the address of the deployer as a payable address.
        // When we withdraw funds, we'll withdraw here.
        owner = payable(msg.sender);
    }

    /**
     * @dev fetches all stored memos
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * @param _name name of the coffee purchaser
     * @param _message a nice message from the purchaser
     */
    function buyCoffee(string memory _name, string memory _message) public payable {
        // Must accept more than 0 ETH for a coffee.
        require(msg.value > 0, "can't buy coffee for free!");

        // Add the memo to storage!
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit a NewMemo event with details about the memo.
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }
}
```

_Crea un script buy-coffee.js para probar tu contrato_.

En la carpeta scripts, debería haber un script de ejemplo ya poblado sample-script.js. Vamos a cambiar
el nombre de ese archivo a buy-coffee.js y pegar el siguiente código:

```
const hre = require("hardhat");

// Returns the Ether balance of a given address.
async function getBalance(address) {
  const balanceBigInt = await hre.ethers.provider.getBalance(address);
  return hre.ethers.utils.formatEther(balanceBigInt);
}

// Logs the Ether balances for a list of addresses.
async function printBalances(addresses) {
  let idx = 0;
  for (const address of addresses) {
    console.log(`Address ${idx} balance: `, await getBalance(address));
    idx ++;
  }
}

// Logs the memos stored on-chain from coffee purchases.
async function printMemos(memos) {
  for (const memo of memos) {
    const timestamp = memo.timestamp;
    const tipper = memo.name;
    const tipperAddress = memo.from;
    const message = memo.message;
    console.log(`At ${timestamp}, ${tipper} (${tipperAddress}) said: "${message}"`);
  }
}

async function main() {
  // Get the example accounts we'll be working with.
  const [owner, tipper, tipper2, tipper3] = await hre.ethers.getSigners();

  // We get the contract to deploy.
  const BuyMeACoffee = await hre.ethers.getContractFactory("BuyMeACoffee");
  const buyMeACoffee = await BuyMeACoffee.deploy();

  // Deploy the contract.
  await buyMeACoffee.deployed();
  console.log("BuyMeACoffee deployed to:", buyMeACoffee.address);

  // Check balances before the coffee purchase.
  const addresses = [owner.address, tipper.address, buyMeACoffee.address];
  console.log("== start ==");
  await printBalances(addresses);

  // Buy the owner a few coffees.
  const tip = {value: hre.ethers.utils.parseEther("1")};
  await buyMeACoffee.connect(tipper).buyCoffee("Carolina", "You're the best!", tip);
  await buyMeACoffee.connect(tipper2).buyCoffee("Vitto", "Amazing teacher", tip);
  await buyMeACoffee.connect(tipper3).buyCoffee("Kay", "I love my Proof of Knowledge", tip);

  // Check balances after the coffee purchase.
  console.log("== bought coffee ==");
  await printBalances(addresses);

  // Withdraw.
  await buyMeACoffee.connect(owner).withdrawTips();

  // Check balances after withdrawal.
  console.log("== withdrawTips ==");
  await printBalances(addresses);

  // Check out the memos.
  console.log("== memos ==");
  const memos = await buyMeACoffee.getMemos();
  printMemos(memos);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

Ahora para la diversión, vamos a ejecutar el script:

```
npx hardhat run scripts/buy-coffee.js
```

Deberías ver la salida en tu terminal así:

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx
hardhat run scripts/buy-coffee.js
Downloading compiler 0.8.17
Compiled 2 Solidity files successfully
BuyMeACoffee deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
== start ==
Address 0 balance:  9999.99857209
Address 1 balance:  10000.0
Address 2 balance:  0.0
== bought coffee ==
Address 0 balance:  9999.99857209
Address 1 balance:  9998.999752217513572352
Address 2 balance:  3.0
== withdrawTips ==
Address 0 balance:  10002.998526175780770316
Address 1 balance:  9998.999752217513572352
Address 2 balance:  0.0
== memos ==
At 1669600347, Carolina (0x70997970C51812dc3A010C7d01b50e0d17dc79C8) said: "You're the best!"
At 1669600348, Vitto (0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC) said: "Amazing teacher"
At 1669600349, Kay (0x90F79bf6EB2c4f870365E785982E1f101E93b906) said: "I love my Proof of Knowledge"
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ tree -C
-L 1
```

_Despliega tu contrato inteligente BuyMeACoffe.sol en la red de pruebas local_

Vamos a crear un nuevo archivo scripts/deploy.js que será super simple, sólo para desplegar nuestro
contrato a cualquier red que elijamos más tarde (elegiremos Goerli más tarde si no te has dado cuenta).

El archivo deploy.js debería tener este aspecto:

```
// scripts/deploy.js

const hre = require("hardhat");

async function main() {
  // We get the contract to deploy.
  const BuyMeACoffee = await hre.ethers.getContractFactory("BuyMeACoffee");
  const buyMeACoffee = await BuyMeACoffee.deploy();

  await buyMeACoffee.deployed();

  console.log("BuyMeACoffee deployed to:", buyMeACoffee.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

```

Ahora con este script deploy.js codificado y guardado, si ejecutas el siguiente comando:

```
npx hardhat run scripts/deploy.js
```

Verás que se imprime una sola línea:

```
BuyMeACoffee deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

Lo interesante es que si lo ejecutas una y otra vez, verás exactamente la misma dirección de
despliegue cada vez:

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx
hardhat run scripts/deploy.js
BuyMeACoffee deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx
hardhat run scripts/deploy.js
BuyMeACoffee deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx
hardhat run scripts/deploy.js
BuyMeACoffee deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx
hardhat run scripts/deploy.js
BuyMeACoffee deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$
```

¿Por qué? Esto se debe a que cuando se ejecuta el script, la red por defecto que utiliza la
herramienta Hardhat es una red de desarrollo local, justo en tu ordenador. Es rápido y determinista y
genial para algunas comprobación rápida.

Despliega tu contrato inteligente BuyMeACoffe.sol en la red de pruebas de Ethereum Goerli utilizando
Alchemy y MetaMask\_.

Cuando abras tu archivo hardhat.config.js, verás un ejemplo de código de despliegue. Elimínalo y pega
esta versión:

```
// hardhat.config.js

require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("dotenv").config()

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const GOERLI_URL = process.env.GOERLI_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: GOERLI_URL,
      accounts: [PRIVATE_KEY]
    }
  }
};
```

Ahora, antes de que podamos hacer nuestro despliegue, necesitamos asegurarnos de que tenemos una
última herramienta instalada, el módulo dotenv. Como su nombre indica, dotenv nos ayuda a conectar un
archivo .env al resto de nuestro proyecto. Vamos a instalarlo.

Instala dotenv:

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npm
install dotenv

added 1 package, and audited 924 packages in 34s

129 packages are looking for funding
  run `npm fund` for details
```

Crear un archivo .env (Usando el IDE VSCode) Rellenar el archivo .env con las variables que
necesitamos:

```
GOERLI_URL=https://eth-goerli.alchemyapi.io/v2/<your api key>
GOERLI_API_KEY=<your api key>
PRIVATE_KEY=<your metamask api key>
```

Además, para obtener lo que necesitas para las variables de entorno, puedes utilizar los siguientes
recursos:

    GOERLI_URL - crea una cuenta en Alchemy, crea una aplicación Ethereum -> Goerli, y utiliza la URL
    HTTP.
    GOERLI_API_KEY - desde tu misma app Alchemy Ethereum Goerli, puedes obtener la última parte de la
    URL, y esa será tu API KEY
    PRIVATE_KEY - Sigue estas instrucciones de MetaMask para exportar tu clave privada.

Asegúrate de que .env aparece en tu .gitignore:

```
node_modules
.env
coverage
coverage.json
typechain
typechain-types

#Hardhat files
cache
artifacts
```

¡Ahora podemos desplegar!
Ejecuta el script de despliegue, esta vez añadiendo una bandera especial para utilizar la red Goerli:

```
npx hardhat run scripts/deploy.js --network goerli
```

Si ves el siguiente error

```
Error: Cannot find module '@nomiclabs/hardhat-waffle'
```

Procedemos a ejecutar la siguiente linea en nuestro terminal:

```
llabori@Xubuntu64Bits-machina-virtual:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npm
install --save-dev @nomiclabs/hardhat-waffle 'ethereum-waffle@^3.0.0'
```

Ejecutamos nuevamente:

```
npx hardhat run scripts/deploy.js --network goerli
```

Obtenemos:

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx
hardhat run scripts/deploy.js --network goerli
BuyMeACoffee deployed to: 0x2eE1DF352C85198c2F6859b74c8BA2c93B3b56f7
```

Verificamos que el SmartContract se encuentra verdaderamente deployado en la Tesnet Goerli usando
https://goerli.etherscan.io/

![Alt text](https://www.github.com/assets.digitalocean.com/articles/alligator/boo.svg "a title")

_Verificar y publicar el código fuente del contrato_

Nos dirigimos a la siguiente dirección:

https://goerli.etherscan.io/verifyContract

y rellenar todos los datos solicitados. Finalmente nosotros vemos (La direccion del SmartContract que
debe usted utilizar es la que obtuvo cuando ejecuto el deploy del mismo en la Tesnet Goerli):

```
The Contract Source code for 0x2eE1DF352C85198c2F6859b74c8BA2c93B3b56f7 has already been verified.
Click here to view the Verified Contract Source Code
```

_Implementar un script para retirada de fondos_

Más adelante, cuando publiquemos nuestro sitio web, necesitaremos una forma de recopilar todos los
consejos increíbles que nos dejen nuestros amigos y fans. ¡Podemos escribir otro script hardhat para
hacer precisamente eso!

Crea un archivo en scripts/withdraw.js

```
// scripts/withdraw.js

const hre = require("hardhat");
const abi = require("../artifacts/contracts/BuyMeACoffee.sol/BuyMeACoffee.json");

async function getBalance(provider, address) {
  const balanceBigInt = await provider.getBalance(address);
  return hre.ethers.utils.formatEther(balanceBigInt);
}

async function main() {
  // Get the contract that has been deployed to Goerli.
  const contractAddress="0x2eE1DF352C85198c2F6859b74c8BA2c93B3b56f7";
  const contractABI = abi.abi;

  // Get the node connection and wallet connection.
  const provider = new hre.ethers.providers.AlchemyProvider("goerli", process.env.GOERLI_API_KEY);

  // Ensure that signer is the SAME address as the original contract deployer,
  // or else this script will fail with an error.
  const signer = new hre.ethers.Wallet(process.env.PRIVATE_KEY, provider);

  // Instantiate connected contract.
  const buyMeACoffee = new hre.ethers.Contract(contractAddress, contractABI, signer);

  // Check starting balances.
  console.log("current balance of owner: ", await getBalance(provider, signer.address), "ETH");
  const contractBalance = await getBalance(provider, buyMeACoffee.address);
  console.log("current balance of contract: ", await getBalance(provider, buyMeACoffee.address),
  "ETH");

  // Withdraw funds if there are funds to withdraw.
  if (contractBalance !== "0.0") {
    console.log("withdrawing funds..")
    const withdrawTxn = await buyMeACoffee.withdrawTips();
    await withdrawTxn.wait();
  } else {
    console.log("no funds to withdraw!");
  }

  // Check ending balance.
  console.log("current balance of owner: ", await getBalance(provider, signer.address), "ETH");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

La parte más importante de este script es cuando llamamos a la función withdrawTips() para sacar
dinero del saldo de nuestro contrato y enviarlo al monedero del propietario:

```
// Withdraw funds if there are funds to withdraw.
  if (contractBalance !== "0.0") {
    console.log("withdrawing funds..")
    const withdrawTxn = await buyMeACoffee.withdrawTips();
    await withdrawTxn.wait();
  }
hasta finalizar
```

Si no hay fondos en el contrato, evitamos intentar retirar para no gastar gas fees innecesariamente.

## Construir el frontend Buy Me A Coffee sitio web dapp con Replit y Ethers.js ⚙️

Para esta parte del sitio web, con el fin de mantener las cosas simples y limpias, vamos a utilizar
una herramienta increíble para hacer girar los proyectos de demostración rápidamente, llamado Replit
IDE.

Visita mi proyecto de ejemplo aquí, y haz un fork para crear tu propia copia para modificar: https://
replit.com/@thatguyintech/BuyMeACoffee-Solidity-DeFi-Tipping-app

Después de bifurcar la réplica, deberías ser llevado a una página del IDE donde puedes:

    Ver el código de una aplicación web Next.js
    Acceder a una consola, un intérprete de comandos de terminal y una vista previa del archivo README.
    md
    Ver una versión de recarga en caliente de tu aplicación.

Esta parte del tutorial será rápida y divertida -- ¡vamos a actualizar un par de variables para que
esté conectada al contrato inteligente que desplegamos en las partes anteriores del proyecto y para
que muestre tu propio nombre en el sitio web!

Primero vamos a conectarlo todo y a ponerlo en marcha, y luego te explicaré qué pasa en cada parte.

Estos son los cambios que tenemos que hacer

    Actualizar el contractAddress en pages/index.js
    Actualizar las cadenas de nombre para ser su propio nombre en pages/index.js
    Asegúrese de que el contrato ABI coincide con su contrato en utils/BuyMeACoffee.json

Actualiza contractAddress en pages/index.js

Puedes ver que la variable contractAddress ya está rellenada con una dirección. Este es un contrato de
ejemplo que he desplegado, que puedes utilizar, pero si lo haces... todos los consejos enviados a tu
sitio web irán a mi dirección :)

Puedes arreglar esto pegando tu dirección de cuando desplegamos el contrato inteligente BuyMeACoffee.
sol anteriormente.

Asegúrate de que el ABI del contrato coincide en utils/BuyMeACoffee.json

Esto también es algo clave a comprobar, especialmente cuando realice cambios en su contrato
inteligente más adelante (después de este tutorial).

La ABI es la interfaz binaria de la aplicación, que no es más que una forma elegante de decirle a
nuestro código frontend qué tipo de funciones están disponibles para llamar en el contrato
inteligente. La ABI se genera dentro de un archivo json cuando se compila el contrato inteligente.
Puedes encontrarlo en la carpeta del contrato inteligente en la ruta artifacts/contracts/BuyMeACoffee.
sol/BuyMeACoffee.json

Siempre que cambies el código de tu contrato inteligente y lo vuelvas a desplegar, tu ABI cambiará
también. Cópielo y péguelo en el archivo Replit: utils/BuyMeACoffee.json

Ahora, si la aplicación aún no se está ejecutando, puedes ir a la shell y utilizar npm run dev para
iniciar un servidor local para probar tus cambios. El sitio web debería cargarse en unos segundos.

```
~/Buy-Me-A-Coffee-DeFi-DApp-Veneh$ npm run dev
```

Lo impresionante de Replit es que una vez que tengas el sitio web, puedes volver a tu perfil,
encontrar el enlace del proyecto Replit, y enviarlo a tus amigos para que visiten tu página de
propinas.

Ahora vamos a dar una vuelta por el sitio web y el código. Ya puedes ver en la captura de pantalla
anterior que la primera vez que visita la aplicación, se comprobará si tiene MetaMask instalado y si
su billetera está conectada al sitio. La primera vez que usted visita, usted no estará conectado, por
lo que un botón se te pedirá que conectes tu monedero.

Después de hacer clic en Conectar su cartera, una ventana MetaMask aparecerá preguntando si desea
confirmar la conexión firmando un mensaje. Esta firma de mensaje no requiere ninguna tasa de gas ni
coste alguno.

Una vez que la firma se haya completado, el sitio web reconocerá tu conexión y podrás ver el
formulario de café, así como cualquiera de los memos anteriores dejados por otros visitantes.

Recapitulando:

    Usamos Hardhat y Ethers.js para codificar, probar y desplegar un contrato inteligente solidity
    personalizado.
    Desplegamos el contrato inteligente en la red de prueba Goerli utilizando Alchemy y MetaMask.
    Implementamos un script de retirada para permitirnos aceptar los frutos de nuestro trabajo.
    Conectamos un sitio web frontend construido con Next.js, React y Replit al contrato inteligente
    utilizando Ethers.js para cargar el ABI del contrato.

¡Eso es un MONTÓN!

## Desafío ⚙️

Bien, ahora es el momento de la mejor parte. Voy a dejarte con algunos retos para que los intentes por
tu cuenta, ¡para ver si entiendes completamente lo que has aprendido aquí!

    Permite que tu contrato inteligente actualice la dirección de retirada.

Implementamos en el Contrato Intelligente los cambios que sean necesarios con la finalidad de que
pueda ser actualizada la direccion hacia donde se pueden retirar los fondos, seguidamente deployamos
el nuevo contrato en la testnet Goerli:

```
llabori@Xubuntu64Bits-máquina-virtual:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx
hardhat run scripts/deploy-upd.js --network goerli
Compilado 1 archivo Solidity con éxito
BuyMeACoffeeUpd desplegado en: 0x2451E511a2E34EbD6C345bF0a5c0af833D800604
```

A continuación verificamos y publicamos en el Código Fuente del Contrato Inteligente:

```
 El Código Fuente del Contrato para 0x2451E511a2E34EbD6C345bF0a5c0af833D800604 ya ha sido verificado.
Haga clic aquí para ver el Código Fuente del Contrato Verificado
```

A continuación ejecutamos el script para retirar todos los fondos del Contrato Inteligente a la
dirección de la Billetera propietaria del contrato.

```
llabori@Xubuntu64Bits-máquina-virtual:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx
hardhat run scripts/withdraw-upd.js
saldo actual del propietario: 1.176838871658965623 ETH
saldo actual del contrato: 0.003 ETH
retirando fondos..
saldo actual del propietario: 1.179774929554468324 ETH
```

Cuando termines tu desafío, tuitea sobre él etiquetando a @AlchemyLearn en Twitter y utilizando el
hashtag #roadtoweb3.

Y asegúrate de compartir tus reflexiones sobre este proyecto para ganar tu Proof of Knowledge (PoK)
token: https://university.alchemy.com/discord

## Construido con 🛠️

_Herramientas que utilizaste para crear tu proyectoHerramientas que utilizaste para desarrollar el
desafio_

- [Visual Studio Code](https://code.visualstudio.com/) - El IDE
- [Replit](https://replit.com) - IDE en línea para Front End
- [Alchemy](https://dashboard.alchemy.com) - Interfaz/API para la Red Goerli Tesnet
- [Xubuntu](https://xubuntu.org/) - Sistema operativo basado en la distribución Ubuntu
- [Goerli Testnet](https://goerli.etherscan.io) - Sistema web utilizado para verificar transacciones,
  verificar contratos, desplegar contratos, verificar y publicar código fuente de contratos, etc.
- [Solidity](https://soliditylang.org) Lenguaje de programación orientado a objetos para implementar
  contratos inteligentes en varias plataformas de cadenas de bloques.
- [Hardhat](https://hardhat.org) - Entorno utilizado por los desarrolladores para probar, compilar,
  desplegar y depurar dApps basadas en la cadena de bloques Ethereum.
- [GitHub](https://github.com/) - Servicio de alojamiento en Internet para el desarrollo de software y
  el control de versiones mediante Git.
- [Goerli Faucet](https://goerlifaucet.com/) - Faucet utilizado para obtener ETH utilizado en las
  pruebas para desplegar las SmartContrat así como para interactuar con ellas.
- [MetaMask](https://metamask.io) - MetaMask es una cartera de criptodivisas de software utilizada
  para interactuar con la blockchain de Ethereum.

## Contribuir 🖇️

Por favor, lee [CONTRIBUTING.md](https://gist.github.com/llabori-venehsoftw/xxxxxx) para más detalles sobre
nuestro código de conducta, y el proceso para enviarnos pull requests.

## Wiki 📖

N/A

## Versionado 📌

Utilizamos [GitHub] para versionar todos los archivos utilizados (https://github.com/tu/proyecto/tags).

## Autores ✒️

_Personas que colaboraron con el desarrollo del reto_.

- **VeneHsoftw** - _Trabajo Inicial_ - [venehsoftw](https://github.com/venehsoftw)
- **Luis Labori** - _Trabajo inicial_, _Documentaciónn_ - [llabori-venehsoftw](https://github.com/
  llabori-venehsoftw)

## Licencia 📄

Este proyecto está licenciado bajo la Licencia (Su Licencia) - ver el archivo [LICENSE.md](LICENSE.md)
para más detalles.

## Gratitud 🎁

- Si la información reflejada en este Repo te ha parecido de gran importancia, por favor, amplía tu
  colaboración pulsando el botón de la estrella en el margen superior derecho. 📢
- Si está dentro de sus posibilidades, puede ampliar su donación a través de la siguiente dirección:
  `0xAeC4F555DbdE299ee034Ca6F42B83Baf8eFA6f0D`

---

⌨️ con ❤️ por [Venehsoftw](https://github.com/llabori-venehsoftw) 😊
