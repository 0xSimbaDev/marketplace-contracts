import { utils, Wallet } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import fs from "fs"

const PRIV_KEY = fs.readFileSync(".secret").toString()

export default async function (hre: HardhatRuntimeEnvironment) {
    console.log(`Running deploy script for the Marketplace Contract.`);
    
    //
    // Initialize the wallet
    const wallet = new Wallet(PRIV_KEY);

    // Create deployer object and load the artifact of the contract we want to deploy.
    const deployer = new Deployer(hre, wallet);
    
    const artifact = await deployer.loadArtifact("Marketplace");
    const marketAddress = "0xa1d22441dE66BB328E8269451B1A28d181C74d11"
    const deploymentFee = await deployer.estimateDeployFee(artifact, [marketAddress]);
    console.log(deploymentFee)

     // Deploy this contract. The returned object will be of a `Contract` type, similarly to ones in `ethers`.
    //const feePercent = 1
    const mintContract = await deployer.deploy(artifact, [marketAddress]);
    console.log("args " + mintContract.interface.encodeDeploy([marketAddress]));

    const contractAddress = mintContract.address;
    console.log(`${artifact.contractName} was deployed to ${contractAddress}`);

}

